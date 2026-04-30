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

---

_If you’re interested in trying it out or contributing, the repository is available here:_  
👉 https://github.com/briancolfer/job_tracker
