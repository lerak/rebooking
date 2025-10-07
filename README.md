# Rebooking - Appointment Management & SMS Communication Platform

A multi-tenant Rails application for managing customer appointments with automated SMS reminders and two-way messaging capabilities powered by Twilio.

## Features

- **Multi-tenant Architecture**: Isolated business workspaces with role-based access control
- **Appointment Management**: Schedule and track customer appointments with status tracking
- **Automated SMS Reminders**: Configurable appointment reminders sent via Twilio
- **Two-Way SMS Communication**: Real-time business inbox with SMS conversations
- **SMS Consent Management**: Automatic opt-in/opt-out handling with STOP/HELP keyword support
- **Multi-Phone Number Support**: Manage multiple Twilio phone numbers per business with location-based assignment
- **Real-time Updates**: Turbo Streams for live inbox updates without page refresh
- **Delivery Tracking**: Monitor message delivery status with Twilio webhook integration

## Technology Stack

- **Ruby**: 3.x
- **Rails**: 8.0.3
- **Database**: PostgreSQL with UUID primary keys
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS 4.3
- **Authentication**: Devise
- **Background Jobs**: Sidekiq with Redis, Sidekiq-Cron for scheduled tasks
- **SMS Integration**: Twilio (twilio-ruby gem)
- **Testing**: RSpec, FactoryBot, Capybara, VCR, WebMock
- **Deployment**: Kamal, Thruster

## Prerequisites

- Ruby 3.x
- PostgreSQL
- Redis (for Sidekiq background jobs)
- Node.js (for asset pipeline)
- Twilio account with phone number(s)

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd rebooking
bundle install
```

### 2. Database Setup

```bash
rails db:create
rails db:migrate
rails db:seed  # Optional: load sample data
```

### 3. Configure Twilio Credentials

Add your Twilio credentials to Rails encrypted credentials:

```bash
rails credentials:edit
```

Add the following keys:

```yaml
twilio:
  account_sid: YOUR_TWILIO_ACCOUNT_SID
  auth_token: YOUR_TWILIO_AUTH_TOKEN
  phone_number: YOUR_TWILIO_PHONE_NUMBER
```

### 4. Start Required Services

```bash
# Start Redis (required for Sidekiq)
redis-server

# Start Sidekiq (in a separate terminal)
bundle exec sidekiq

# Start Rails server
bin/dev  # or rails server
```

### 5. Configure Twilio Webhooks

In your Twilio console, configure the following webhook URLs for your phone number:

- **Inbound Messages**: `https://yourdomain.com/webhooks/twilio/inbound`
- **Status Callbacks**: `https://yourdomain.com/webhooks/twilio/status`

For local development, use a tunneling service like ngrok:

```bash
ngrok http 3000
# Use the ngrok URL for webhook configuration
```

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/message_spec.rb

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

## Key Models

- **Business**: Multi-tenant organization with Twilio configuration
- **User**: Authenticated users with role-based access (admin/staff)
- **Customer**: Business customers with phone numbers and SMS consent status
- **Appointment**: Scheduled appointments with automated reminder support
- **Message**: SMS messages (inbound/outbound) with delivery tracking
- **ConsentLog**: Audit trail for SMS opt-in/opt-out events
- **TwilioPhoneNumber**: Additional phone numbers with location-based assignment

## Background Jobs

- **ScheduleAppointmentRemindersJob**: Runs hourly via Sidekiq-Cron to queue upcoming appointment reminders
- **SendAppointmentReminderJob**: Formats and sends individual appointment reminders
- **SendMessageJob**: Handles SMS delivery via Twilio with consent checking and error handling

## SMS Consent & Compliance

- Automatic consent logging when customers are created
- STOP keyword automatically opts customers out of future messages
- HELP keyword triggers automated business contact info response
- All consent events tracked in ConsentLog with timestamps
- Messages blocked for opted-out customers with audit logging

## Multi-Phone Number Management

Businesses can request additional Twilio phone numbers for different locations:

1. Navigate to Settings > Phone Numbers
2. Request a new phone number with location identifier
3. Admin approves request (manual process in MVP)
4. Approved numbers can be assigned to appointments by location
5. Messages sent using location-matched phone number when available

## Deployment

This application is configured for deployment with Kamal:

```bash
# Deploy to production
kamal deploy

# Other Kamal commands
kamal setup     # Initial server setup
kamal redeploy  # Deploy without rebuilding
kamal app logs  # View application logs
```

## Admin Tasks

### Approve Phone Number Requests

```bash
rails console
> phone_number = TwilioPhoneNumber.find_by(status: :pending)
> phone_number.update(status: :approved, phone_number: '+1234567890')
```

### View Message Delivery Stats

```bash
rails console
> Message.group(:status).count
```

## Development

- Follow Rails conventions for MVC structure
- Use RSpec for all new features (models, controllers, jobs, system specs)
- Use VCR for recording/mocking external API calls (Twilio)
- Ensure all Turbo Stream broadcasts are tested
- Keep background jobs idempotent

## Troubleshooting

### Messages Not Sending

1. Verify Twilio credentials in Rails credentials
2. Check Sidekiq is running and processing jobs
3. Check message status and error_message field
4. Review Twilio console for API errors

### Webhooks Not Working

1. Verify webhook URLs in Twilio console
2. Check webhook signature verification is working
3. Review Rails logs for webhook errors
4. For local dev, ensure ngrok tunnel is active

### Background Jobs Not Running

1. Verify Redis is running
2. Check Sidekiq process is active
3. Review `config/sidekiq.yml` for cron schedule
4. Check Sidekiq logs for errors

## Contributing

1. Create feature branch from `main`
2. Write tests for new functionality
3. Ensure all tests pass: `bundle exec rspec`
4. Submit pull request with clear description

## License

[Specify your license here]
