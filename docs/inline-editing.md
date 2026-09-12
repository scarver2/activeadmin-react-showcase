<!-- docs/inline-editing.md -->

# Optimistic Inline Editing

## Demo

The ActiveAdmin page stays server rendered. Each status or eligible region cell mounts one deliberately small React island. Click or press Enter on a value, choose an allowlisted option, then save with Enter. Escape cancels and focus returns to the activating value.

## Ruby

`InlineEditing::Policy` makes both record and field decisions. Status is editable for every account; region is editable only while the synthetic account is active. Name, plan, and every unlisted parameter are forbidden. `InlineEditing::Update` applies model validation and Active Record's `lock_version` conflict detection.

## JavaScript

The island owns only transient editor, saving, and error state. It presents the proposed value optimistically. Rejection or network failure rolls back; a stale response supplies the newest canonical value and lock version. Focus is restored after save, failure, blur, or Escape.

## Architecture

Rails owns authorization, validation, persistence, concurrency, and canonical rendering. React enhances one field without replacing the ActiveAdmin table. The normal ActiveAdmin show and narrowly permitted edit/update pages remain available when JavaScript is absent.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
