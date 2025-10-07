# Task List: Messaging MVP - Two-Way SMS Communication

Based on PRD: `0002-prd-messaging-mvp.md`

## Relevant Files

### Core Application Files
- `Gemfile` - Add twilio-ruby gem dependency
- `config/initializers/twilio.rb` - Twilio API configuration and credentials
- `config/credentials.yml.enc` - Store Twilio account SID, auth token, and phone number
- `config/routes.rb` - Add webhook routes and messaging routes

### Models
- `app/models/message.rb` - Already exists, needs status enum updates for delivery tracking
- `app/models/consent_log.rb` - Already exists, needs event_type enum and consent status methods
- `app/models/customer.rb` - Add consent status helpers and phone formatting
- `app/models/business.rb` - Add twilio_phone_number and reminder_hours_before fields
- `app/models/twilio_phone_number.rb` - New model for multi-number management

### Jobs
- `app/jobs/send_message_job.rb` - Background job to send SMS via Twilio REST API
- `app/jobs/send_appointment_reminder_job.rb` - Job to queue appointment reminders
- `app/jobs/schedule_appointment_reminders_job.rb` - Cron job to schedule upcoming reminders

### Controllers
- `app/controllers/twilio_webhooks_controller.rb` - Handle inbound SMS and delivery status callbacks
- `app/controllers/messages_controller.rb` - Already exists, needs inbox and send actions
- `app/controllers/settings/twilio_phone_numbers_controller.rb` - Manage additional phone numbers

### Services
- `app/services/twilio_service.rb` - Wrapper for Twilio API interactions
- `app/services/consent_manager.rb` - Handle opt-in/opt-out logic
- `app/services/message_parser.rb` - Parse STOP/HELP keywords

### Views
- `app/views/messages/index.html.erb` - Inbox UI with conversation list
- `app/views/messages/_conversation.html.erb` - Single conversation partial
- `app/views/messages/_message.html.erb` - Message bubble partial
- `app/views/messages/inbox.turbo_stream.erb` - Turbo Stream for real-time updates
- `app/views/settings/twilio_phone_numbers/index.html.erb` - Phone number management UI
- `app/views/settings/twilio_phone_numbers/new.html.erb` - Request new phone number form

### JavaScript/Stimulus
- `app/javascript/controllers/inbox_controller.js` - Handle inbox interactions and notifications
- `app/javascript/controllers/message_form_controller.js` - Handle message sending

### Database Migrations
- `db/migrate/[timestamp]_add_twilio_fields_to_businesses.rb` - Add twilio_phone_number, reminder_hours_before
- `db/migrate/[timestamp]_add_delivery_tracking_to_messages.rb` - Add twilio_sid, error_message, delivered_at
- `db/migrate/[timestamp]_add_consent_fields_to_consent_logs.rb` - Add event_type, metadata
- `db/migrate/[timestamp]_add_sms_consent_to_customers.rb` - Add sms_consent_status, opted_out_at
- `db/migrate/[timestamp]_create_twilio_phone_numbers.rb` - Create phone number management table
- `db/migrate/[timestamp]_add_read_status_to_messages.rb` - Add read_at for unread indicators

### Tests (RSpec)
- `spec/models/message_spec.rb` - Already exists, add delivery status tests
- `spec/models/consent_log_spec.rb` - Already exists, add event type tests
- `spec/models/customer_spec.rb` - Already exists, add consent status tests
- `spec/models/business_spec.rb` - Already exists, add twilio config tests
- `spec/models/twilio_phone_number_spec.rb` - Model validations and associations
- `spec/jobs/send_message_job_spec.rb` - Test Twilio API integration with mocks
- `spec/jobs/send_appointment_reminder_job_spec.rb` - Test reminder queueing logic
- `spec/jobs/schedule_appointment_reminders_job_spec.rb` - Test cron scheduling
- `spec/controllers/twilio_webhooks_controller_spec.rb` - Test webhook signature verification and processing
- `spec/requests/messages_spec.rb` - Already exists, add inbox and send endpoints
- `spec/requests/settings/twilio_phone_numbers_spec.rb` - Phone number management requests
- `spec/services/twilio_service_spec.rb` - Test API wrapper with VCR cassettes
- `spec/services/consent_manager_spec.rb` - Test opt-in/opt-out flows
- `spec/services/message_parser_spec.rb` - Test STOP/HELP parsing
- `spec/system/messaging_inbox_spec.rb` - End-to-end inbox functionality
- `spec/system/appointment_reminders_spec.rb` - End-to-end reminder flow

### Configuration
- `config/sidekiq.yml` - Configure reminder scheduling cron job
- `.env.example` - Document required Twilio environment variables

### Notes
- Tests should use RSpec with FactoryBot for fixtures
- Use VCR gem for recording/mocking Twilio API interactions in tests
- Use Webmock to stub HTTP requests in tests
- Run tests with `bundle exec rspec` or `bundle exec rspec spec/path/to/file_spec.rb`
- Follow existing Rails conventions for controller/model/job structure
- Ensure all Turbo Stream broadcasts are tested with system specs

## Tasks

- [x] 1.0 Setup Twilio Integration & Infrastructure
  - [x] 1.1 Add twilio-ruby gem to Gemfile and run bundle install
  - [x] 1.2 Create Twilio initializer with configuration (account SID, auth token, phone number from credentials)
  - [x] 1.3 Add Twilio credentials to Rails encrypted credentials (twilio_account_sid, twilio_auth_token, twilio_phone_number)
  - [x] 1.4 Create TwilioService class to wrap Twilio REST API client for sending SMS
  - [x] 1.5 Write RSpec tests for TwilioService with VCR cassettes to mock API calls
  - [x] 1.6 Add VCR and Webmock gems to test group in Gemfile for API mocking
  - [x] 1.7 Configure VCR in spec/support/vcr.rb for recording Twilio interactions
  - [x] 1.8 Test TwilioService can successfully send a test SMS (use test mode or real API with valid credentials)

- [x] 2.0 Implement SMS Consent Management System
  - [x] 2.1 Create migration to add event_type enum (opted_in, opted_out) and metadata jsonb to consent_logs table
  - [x] 2.2 Create migration to add sms_consent_status enum (pending, active, opted_out) and opted_out_at timestamp to customers table
  - [x] 2.3 Update ConsentLog model with event_type enum and validations
  - [x] 2.4 Update Customer model with sms_consent_status enum and consent helper methods (consented?, opted_out?, can_receive_sms?)
  - [x] 2.5 Create ConsentManager service to handle opt-in logic (create consent log, update customer status)
  - [x] 2.6 Add opt-out logic to ConsentManager (process STOP keyword, update customer status, log event)
  - [x] 2.7 Create MessageParser service to detect STOP/HELP keywords in message body
  - [x] 2.8 Write RSpec tests for ConsentLog model (validations, associations, event types)
  - [x] 2.9 Write RSpec tests for Customer model consent methods (consented?, opted_out?, can_receive_sms?)
  - [x] 2.10 Write RSpec tests for ConsentManager service (opt-in, opt-out flows, edge cases)
  - [x] 2.11 Write RSpec tests for MessageParser service (STOP/HELP detection, case insensitivity)
  - [x] 2.12 Add automatic consent creation when customer is created with phone number (after_create callback)
  - [x] 2.13 Test automatic consent creation in customer_spec.rb

- [x] 3.0 Build Automated Appointment Reminder System
  - [x] 3.1 Create migration to add twilio_phone_number and reminder_hours_before (default 24) to businesses table
  - [x] 3.2 Update Business model with twilio configuration fields and validations
  - [x] 3.3 Create SendMessageJob to send SMS via TwilioService (accept customer, message body, business)
  - [x] 3.4 Create SendAppointmentReminderJob to format and queue reminder message for an appointment
  - [x] 3.5 Create ScheduleAppointmentRemindersJob (cron job) to find upcoming appointments and queue reminders
  - [x] 3.6 Add Sidekiq cron configuration in config/sidekiq.yml to run ScheduleAppointmentRemindersJob every hour
  - [x] 3.7 Implement consent check in SendMessageJob (skip if customer opted out, log skipped message)
  - [x] 3.8 Create migration to add twilio_sid, error_message, and delivered_at to messages table
  - [x] 3.9 Update Message model status enum to include queued, sent, delivered, failed, undelivered
  - [x] 3.10 Write RSpec tests for SendMessageJob with mocked TwilioService (success and failure cases)
  - [x] 3.11 Write RSpec tests for SendAppointmentReminderJob (message format, consent check, queueing)
  - [x] 3.12 Write RSpec tests for ScheduleAppointmentRemindersJob (find appointments, queue reminders, idempotency)
  - [x] 3.13 Write system spec for end-to-end appointment reminder flow (create appointment → job runs → message sent)
  - [x] 3.14 Add Business settings UI to configure reminder_hours_before in settings/businesses/edit view
  - [x] 3.15 Test Business settings update for reminder configuration in settings/businesses_spec.rb

- [x] 4.0 Develop Twilio Webhook Handler for Inbound Messages
  - [x] 4.1 Create TwilioWebhooksController with inbound and status_callback actions
  - [x] 4.2 Add webhook routes to config/routes.rb (POST /webhooks/twilio/inbound, POST /webhooks/twilio/status)
  - [x] 4.3 Implement Twilio signature verification in TwilioWebhooksController (skip CSRF for webhooks)
  - [x] 4.4 Implement inbound action to parse Twilio webhook params (From, Body, MessageSid)
  - [x] 4.5 Find or create customer by phone number in inbound action
  - [x] 4.6 Create Message record for inbound SMS with direction=inbound, status=received
  - [x] 4.7 Check for STOP/HELP keywords using MessageParser and process accordingly
  - [x] 4.8 Send auto-reply for HELP keyword with business contact info
  - [x] 4.9 Implement status_callback action to update message delivery status (twilio_sid lookup)
  - [x] 4.10 Update message status, delivered_at, and error_message based on callback params
  - [x] 4.11 Broadcast Turbo Stream for new inbound messages to update inbox in real-time
  - [x] 4.12 Write RSpec request tests for TwilioWebhooksController inbound action (valid/invalid signature, message creation)
  - [x] 4.13 Write RSpec request tests for status_callback action (delivery status updates, error handling)
  - [x] 4.14 Test STOP keyword processing (opt-out customer, no further messages sent)
  - [x] 4.15 Test HELP keyword processing (auto-reply with correct content)
  - [x] 4.16 Configure Twilio webhook URLs in Twilio console (point to /webhooks/twilio/inbound and /webhooks/twilio/status)

- [ ] 5.0 Create Business Inbox UI with Real-time Updates
  - [x] 5.1 Update MessagesController with inbox action to load conversations grouped by customer
  - [x] 5.2 Add create action to MessagesController for sending manual replies
  - [x] 5.3 Update routes to add POST /messages (create) and keep GET /messages (inbox)
  - [x] 5.4 Create messages/index.html.erb with two-column layout (conversation list left, message thread right)
  - [x] 5.5 Create _conversation.html.erb partial to display customer info, last message preview, timestamp
  - [x] 5.6 Create _message.html.erb partial with message bubble, status indicator, timestamp
  - [x] 5.7 Add message status indicators (queued=clock, sent=checkmark, delivered=double-check, failed=exclamation)
  - [x] 5.8 Create migration to add read_at timestamp to messages for unread indicators
  - [x] 5.9 Add unread indicator (bold text or badge) for conversations with unread messages
  - [x] 5.10 Implement message form in inbox to send manual replies (Turbo Frame)
  - [x] 5.11 Create Stimulus inbox_controller.js to handle conversation selection and scroll behavior
  - [x] 5.12 Create Stimulus message_form_controller.js to handle message submission
  - [x] 5.13 Implement Turbo Stream broadcast on message creation to update all connected inboxes
  - [x] 5.14 Add browser notification support in inbox_controller.js for new inbound messages
  - [x] 5.15 Create messages/inbox.turbo_stream.erb for real-time message updates
  - [x] 5.16 Add conversation filtering by customer/date/status (optional filter form)
  - [x] 5.17 Format timestamps as "Today at 2:30 PM", "Yesterday at 1:15 PM", "Jan 5 at 3:00 PM" (helper method)
  - [x] 5.18 Write RSpec request tests for MessagesController inbox action (load conversations, authorization)
  - [x] 5.19 Write RSpec request tests for MessagesController create action (send message, broadcast stream)
  - [x] 5.20 Write system spec for inbox UI (view conversations, send message, real-time updates)
  - [x] 5.21 Add ARIA labels for accessibility (screen reader support for message status)
  - [x] 5.22 Test keyboard navigation in system spec (tab through conversations, send with Enter)

- [x] 5.0 Create Business Inbox UI with Real-time Updates

- [ ] 6.0 Implement Multi-Phone Number Management
  - [x] 6.1 Create TwilioPhoneNumber model with business_id, phone_number, status (pending, approved, active), location
  - [x] 6.2 Create migration for twilio_phone_numbers table (id, business_id, phone_number, status, location, created_at, updated_at)
  - [x] 6.3 Add associations (Business has_many twilio_phone_numbers, TwilioPhoneNumber belongs_to business)
  - [x] 6.4 Create Settings::TwilioPhoneNumbersController for phone number management (index, new, create)
  - [x] 6.5 Add routes for phone number management (namespace settings, resources twilio_phone_numbers)
  - [x] 6.6 Create settings/twilio_phone_numbers/index.html.erb to list phone numbers and their status
  - [x] 6.7 Create settings/twilio_phone_numbers/new.html.erb form to request new phone number (location field)
  - [x] 6.8 Implement create action to create phone number request with status=pending
  - [x] 6.9 Add admin approval workflow (manual for MVP - update status to approved via rails console)
  - [x] 6.10 Update SendMessageJob to use business.twilio_phone_number or appointment.business.twilio_phone_numbers.find_by(location: appointment.location)
  - [x] 6.11 Add location field to appointments table (migration) to support location-based phone number assignment
  - [x] 6.12 Write RSpec model tests for TwilioPhoneNumber (validations, associations, status enum)
  - [x] 6.13 Write RSpec request tests for Settings::TwilioPhoneNumbersController (index, create, authorization)
  - [x] 6.14 Write system spec for phone number request flow (request → pending status → admin approval)
  - [x] 6.15 Document admin approval process in README or setup guide
