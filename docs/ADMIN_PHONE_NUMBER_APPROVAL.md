# Admin Phone Number Approval Process

This document describes how administrators can approve Twilio phone number requests submitted by businesses.

## Overview

When a business requests a new Twilio phone number through the Settings > Twilio Phone Numbers interface, the request is created with a `pending` status and requires manual admin approval.

## Approval Workflow

### 1. View Pending Requests

Open Rails console:
```bash
bin/rails console
```

List all pending phone number requests:
```ruby
TwilioPhoneNumber.pending.includes(:business).each do |request|
  puts "ID: #{request.id}"
  puts "Business: #{request.business.name}"
  puts "Phone Number: #{request.phone_number}"
  puts "Location: #{request.location}"
  puts "Requested: #{request.created_at}"
  puts "---"
end
```

### 2. Approve a Request

To approve a phone number request:
```ruby
# Find the request by ID
request = TwilioPhoneNumber.find("phone-number-id-here")

# Approve it
request.approve!
```

### 3. Activate a Phone Number

Once the phone number has been provisioned in Twilio, activate it:
```ruby
request = TwilioPhoneNumber.find("phone-number-id-here")
request.activate!
```

### 4. Reject a Request

To reject a phone number request (this will delete the record):
```ruby
request = TwilioPhoneNumber.find("phone-number-id-here")
request.reject!
```

## Status Flow

- **pending** → Request submitted, awaiting admin review
- **approved** → Admin approved, phone number being provisioned
- **active** → Phone number is active and ready to use

## Helper Methods

The `TwilioPhoneNumber` model provides three helper methods for admin operations:

- `approve!` - Changes status from pending to approved
- `activate!` - Changes status from approved to active
- `reject!` - Deletes the request (for denied requests)

## Security Considerations

- Only administrators should have access to Rails console in production
- Verify the business and phone number details before approving
- Ensure the phone number exists in your Twilio account before activating
- Keep an audit log of approvals (future enhancement)

## Future Enhancements

For production use, consider building:
- Admin dashboard UI for approving/rejecting requests
- Email notifications to businesses when requests are approved/rejected
- Audit log for tracking who approved which requests
- Automatic phone number provisioning via Twilio API
