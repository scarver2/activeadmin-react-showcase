# db/migrate/20260929130000_adopt_noticed_notifications.rb
# frozen_string_literal: true

class AdoptNoticedNotifications < ActiveRecord::Migration[8.1]
  def up
    create_table :noticed_events do |table|
      table.string :type, null: false
      table.references :record, polymorphic: true
      table.json :params, null: false, default: {}
      table.integer :notifications_count, null: false, default: 0
      table.timestamps
    end

    create_table :noticed_notifications do |table|
      table.string :type, null: false
      table.references :event, null: false, foreign_key: { to_table: :noticed_events }
      table.references :recipient, polymorphic: true, null: false
      table.datetime :read_at
      table.datetime :seen_at
      table.timestamps
    end

    migrate_activity_notifications
    drop_table :activity_notifications
  end

  def down
    create_table :activity_notifications do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :kind, null: false
      table.string :subject, null: false
      table.text :body, null: false
      table.string :deep_link, null: false
      table.datetime :occurred_at, null: false
      table.datetime :read_at
      table.integer :sequence, null: false
      table.timestamps
    end
    add_index :activity_notifications, %i[admin_user_id sequence], unique: true
    add_index :activity_notifications, %i[admin_user_id occurred_at]

    restore_activity_notifications
    drop_table :noticed_notifications
    drop_table :noticed_events
  end

  private

  def migrate_activity_notifications
    connection.select_all("SELECT * FROM activity_notifications ORDER BY id").each do |legacy|
      event_id = insert_record(
        :noticed_events,
        created_at: legacy.fetch("created_at"),
        notifications_count: 1,
        params: {
          body: legacy.fetch("body"),
          deep_link: legacy.fetch("deep_link"),
          kind: legacy.fetch("kind"),
          occurred_at: legacy.fetch("occurred_at"),
          subject: legacy.fetch("subject")
        }.to_json,
        type: "ActivityNotifier",
        updated_at: legacy.fetch("updated_at")
      )
      insert_record(
        :noticed_notifications,
        created_at: legacy.fetch("created_at"),
        event_id:,
        read_at: legacy.fetch("read_at"),
        recipient_id: legacy.fetch("admin_user_id"),
        recipient_type: "AdminUser",
        type: "ActivityNotifier::Notification",
        updated_at: legacy.fetch("updated_at")
      )
    end
  end

  def restore_activity_notifications
    sequences = Hash.new(0)
    rows = connection.select_all(<<~SQL.squish)
      SELECT noticed_notifications.*, noticed_events.params AS event_params
      FROM noticed_notifications
      INNER JOIN noticed_events ON noticed_events.id = noticed_notifications.event_id
      ORDER BY noticed_notifications.id
    SQL
    rows.each do |notification|
      next unless notification.fetch("recipient_type") == "AdminUser"

      params = JSON.parse(notification.fetch("event_params"))
      recipient_id = notification.fetch("recipient_id")
      sequences[recipient_id] += 1
      insert_record(
        :activity_notifications,
        admin_user_id: recipient_id,
        body: params.fetch("body"),
        created_at: notification.fetch("created_at"),
        deep_link: params.fetch("deep_link"),
        kind: params.fetch("kind"),
        occurred_at: params.fetch("occurred_at"),
        read_at: notification.fetch("read_at"),
        sequence: sequences.fetch(recipient_id),
        subject: params.fetch("subject"),
        updated_at: notification.fetch("updated_at")
      )
    end
  end

  def insert_record(table, attributes)
    columns = attributes.keys.map { |column| connection.quote_column_name(column) }.join(", ")
    values = attributes.values.map { |value| connection.quote(value) }.join(", ")
    connection.execute("INSERT INTO #{connection.quote_table_name(table)} (#{columns}) VALUES (#{values})")
    connection.select_value("SELECT MAX(id) FROM #{connection.quote_table_name(table)}").to_i
  end
end
