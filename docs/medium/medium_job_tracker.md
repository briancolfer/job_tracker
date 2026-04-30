# A Local-First Job Tracker with a Web and CLI Interface

## The Problem

A lot of people have been laid off recently, and many are overwhelmed trying to keep track of their job search.

Spreadsheets are flexible, but they quickly become messy and hard to maintain. Rows get inconsistent, notes are scattered, and over time the system breaks down.

Software-as-a-Service tools solve some of that, but they come with tradeoffs. Your data lives somewhere else, and most tools are built around a UI that can feel slow or limiting when you just want to quickly update or query your data.

## A Simpler Approach

I wanted something simpler.

I wanted a tool that:
- Keeps the data local
- Is fast to interact with
- Doesn’t require accounts or setup friction
- Supports both structured tracking and quick updates

## The Solution

This project is a locally installed job tracking application with both a web interface and a command line interface.

The goal is straightforward:
- Capture job applications quickly  
- Update status without friction  
- Review progress in a clear, structured way  

The web interface provides a simple, visual way to manage your job search.

The command line interface provides a fast, scriptable way to interact with your data when you don’t want to open a browser.

## Why Local-First?

Keeping data local was a deliberate decision.

- No accounts to manage  
- No external dependencies  
- Full control over your data  
- Faster iteration and simpler architecture  

This isn’t meant to replace every SaaS tool. It’s meant to provide a focused, low-friction alternative.

## What This Article Covers

In the rest of this article, I’ll walk through:

- The design decisions behind the application  
- Why I chose a web + CLI hybrid approach  
- Tradeoffs I made (and what I intentionally avoided)  
- How to run the application locally  
- How to integrate with the cli


## Design Decisions

This project is intentionally simple, but that simplicity comes from a series of deliberate decisions.

### Local-First by Default

I chose to keep this application local-first.

That means:
- No user accounts
- No remote database
- No dependency on external services

This reduces friction for users and keeps the system easy to understand and maintain.

It also aligns with the idea that a job search is personal. Your data stays with you.

---

### Web + Command Line Interface

Most tools choose one interface. This project supports both.

The web interface provides:
- A clear, visual way to review and manage applications
- A familiar experience for most users

The command line interface provides:
- Fast data entry
- Scriptable workflows
- The ability to interact with the system without context switching

This combination allows different interaction styles without adding significant complexity to the core system.

---

### Focused Data Model

The application centers around a small number of concepts:
- Job application
- Status
- Notes

Rather than trying to model every possible aspect of a job search, the goal is to support the most common workflows well.

This keeps the system flexible without becoming complex.

---

### Minimal Dependencies

The application avoids unnecessary dependencies and external integrations.

This makes it:
- Easier to install
- Easier to debug
- Easier to evolve

It also reduces long-term maintenance overhead.

---

## Tradeoffs

Every decision in this project comes with tradeoffs.

### No SaaS (for now)

By not building this as a SaaS application:

**Pros:**
- Full control over data
- No authentication complexity
- Faster development and iteration

**Cons:**
- No access from multiple devices
- No centralized updates
- No built-in sharing

This is an intentional constraint, not a limitation.

---

### Limited Feature Set

This application does not attempt to cover every possible feature:
- No automated job imports
- No integrations with job boards
- No notifications or reminders

The goal is to avoid feature creep and focus on a clean, reliable core.

---

### CLI as a First-Class Interface

Supporting a CLI adds complexity:
- Requires a stable interface
- Requires documentation
- Adds another surface area to maintain

However, it provides a significant benefit for users who prefer fast, direct interaction.

---

## Running the Application

The application is designed to be easy to run locally.

### Using Docker

```bash
docker run -d \
  -p 3000:3000 \
  -v job_tracker_data:/app/storage \
  your-image:latest
```

This approach:
- Avoids local Ruby and Rails setup
- Keeps the data on your local drive
- Works with either docker or podman

### Local Setup

For those who prefer to run the application locally without containers:

```bash
bundle install
bin/rails db:prepare
bin/rails server
```
Then visit:


---

_If you’re interested in trying it out or contributing, the repository is available here:_  
👉 https://github.com/briancolfer/job_tracker
