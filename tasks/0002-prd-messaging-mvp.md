# PRD: Messaging MVP - Two-Way SMS Communication

## 1. Introduction/Overview

The Messaging MVP enables compliant two-way SMS communication between businesses and their customers through Twilio integration. The primary use case is sending automated appointment reminders to reduce no-shows, not marketing. The feature provides a live inbox for businesses to monitor conversations, handle customer replies, and maintain SMS consent compliance with TCPA regulations.

**Problem Solved:** Businesses need a reliable way to remind customers about upcoming appointments via SMS while maintaining compliance with SMS regulations and handling customer responses in real-time.

**Goal:** Deliver a functional, compliant SMS messaging system that reduces no-shows through automated reminders and enables businesses to respond to customer inquiries.

---

## 2. Goals

1. Enable businesses to send automated appointment reminder SMS messages to customers
2. Provide two-way SMS communication for customer replies and business responses
3. Maintain TCPA compliance through proper consent management (opt-in/opt-out)
4. Deliver real-time inbox updates for incoming messages
5. Achieve 95%+ message delivery rate through reliable Twilio integration
6. Support multi-location businesses with multiple Twilio phone numbers (approval-based)

---

## 3. User Stories

**As a business owner/staff member, I want to:**
- Automatically send appointment reminder SMS to customers X hours before their appointment, so they don't forget and miss their booking
- See all SMS conversations with customers in a live inbox, so I can monitor and respond to replies
- Know that only customers who have opted-in receive messages, so I remain compliant with SMS regulations
- Receive notifications when customers reply to messages, so I can respond promptly
- Request additional Twilio phone numbers for different business locations, so each location has its own messaging identity

**As a customer, I want to:**
- Receive appointment reminders with date, time, and business name, so I know when and where to show up
- Reply STOP to unsubscribe from messages, so I have control over what I receive
- Reply HELP to get support information, so I know how to contact the business

---

## 4. Functional Requirements

### 4.1 Automated Appointment Reminders
1. The system must automatically queue SMS reminders X hours before an appointment (configurable per business)
2. Reminder messages must include: appointment date, time, and business name
3. Reminders must only be sent to customers with active consent status
4. The system must use Sidekiq background jobs to send messages asynchronously
5. Messages must be sent via Twilio REST API

### 4.2 Consent Management
6. The system must record consent when a customer provides their phone number during booking (single opt-in)
7. The system must process STOP keyword replies and immediately opt-out the customer
8. The system must log all consent events (opt-in, opt-out) with timestamps in ConsentLog table
9. Opted-out customers must not receive any future messages
10. The system must auto-reply to HELP keyword with business contact info and unsubscribe instructions

### 4.3 Inbound Message Handling
11. The system must receive inbound SMS via Twilio webhook (TwilioWebhooksController)
12. All inbound messages must be saved to MessageLog table
13. The system must broadcast new messages to the business inbox via Turbo Streams in real-time
14. The system must parse and handle STOP/HELP keywords automatically

### 4.4 Message Delivery & Tracking
15. The system must track message delivery status via Twilio status callbacks (queued, sent, delivered, failed, undelivered)
16. Failed messages must be marked with error details in MessageLog
17. The system must provide delivery status indicators in the inbox UI (sent, delivered, failed)
18. All outbound and inbound messages must be persisted in MessageLog with timestamps

### 4.5 Business Inbox UI
19. The inbox must display all conversations sorted by most recent activity
20. The inbox must show customer name, phone number, last message preview, and timestamp
21. The inbox must filter conversations by customer/date/status
22. The inbox must indicate unread messages with visual indicators
23. Staff must be able to manually send replies through the inbox interface
24. The inbox must update in real-time using Turbo Streams when new messages arrive

### 4.6 Notifications
25. Businesses must receive browser notifications for new inbound messages (if enabled)
26. Businesses must receive email notifications for new inbound messages (configurable)

### 4.7 Multi-Phone Number Support
27. The system must allow businesses to request additional Twilio phone numbers through a UI workflow
28. Additional phone number requests must require admin approval
29. Once approved, businesses must be able to assign phone numbers to specific locations
30. Messages must be sent from the phone number assigned to the appointment's business location

---

## 5. Non-Goals (Out of Scope for MVP)

- MMS support (images, videos, media attachments)
- Scheduled/delayed messages (send at specific future time)
- Bulk messaging or marketing campaigns
- Message templates library (future enhancement)
- Message search functionality
- Character/SMS segment counter
- Message history export
- Customer-facing message portal
- Multi-language support
- Delivery reports/analytics dashboard

---

## 6. Design Considerations

### UI/UX Requirements
- Inbox should use a chat-like interface similar to messaging apps (left: conversation list, right: message thread)
- Use Turbo Streams for live updates without page refresh
- Visual indicators: green dot for delivered, red for failed, clock icon for queued/sent
- Unread messages should have bold text or background highlight
- Timestamp format: "Today at 2:30 PM", "Yesterday at 1:15 PM", "Jan 5 at 3:00 PM"

### Accessibility
- Ensure proper ARIA labels for screen readers
- Keyboard navigation support for inbox
- High contrast mode support for message status indicators

---

## 7. Technical Considerations

### Architecture
- **SendMessageJob:** Sidekiq background job to send SMS via Twilio REST API
- **TwilioWebhooksController:** Handles inbound messages and delivery status callbacks
- **MessageLog model:** Stores all messages (direction, status, body, timestamps)
- **ConsentLog model:** Tracks opt-in/opt-out events with timestamps
- **Turbo Stream broadcasts:** Real-time inbox updates via Action Cable

### Dependencies
- Twilio Ruby SDK (twilio-ruby gem)
- Sidekiq for background job processing
- Redis for Sidekiq and Action Cable
- Rails 8 + Hotwire (Turbo Streams)

### Security & Compliance
- Webhook endpoint must verify Twilio signature for authenticity
- Phone numbers must be stored in E.164 format
- All consent changes must be immutable audit logs
- TCPA compliance: honor STOP immediately, maintain opt-out list

### Rate Limiting
- Implement per-business rate limiting (e.g., max 100 messages/hour) to prevent abuse
- Global rate limiting based on Twilio account limits
- Queue messages during rate limit periods and retry

### Data Retention
- Message logs retained indefinitely for compliance and audit purposes
- Consider archiving messages older than 2 years to separate storage (future)

---

## 8. Success Metrics

1. **Message Delivery Rate:** 95%+ of queued messages successfully delivered
2. **System Uptime:** 99.5%+ availability for sending and receiving messages
3. **Webhook Processing:** <500ms average processing time for inbound messages
4. **Real-time Updates:** Messages appear in inbox within 2 seconds of receipt
5. **Compliance:** 100% of STOP requests processed immediately with no further messages sent

---

## 9. Open Questions

1. What is the default value for "X hours before appointment" for reminder timing? (e.g., 24 hours, 48 hours?)
2. Should there be a business setting to enable/disable automatic reminders per appointment type?
3. What happens if a customer replies to a reminder with questions? Does it create a support ticket or just show in inbox?
4. Should admin approval for additional phone numbers include a review process/criteria?
5. Are there any Twilio account spending limits we should enforce at the application level?
6. Should we support international phone numbers or restrict to specific countries initially?
7. What is the fallback behavior if Twilio API is down? (retry logic, notification to business?)
8. Should customers be able to opt-in again after opting out, or is it permanent?
