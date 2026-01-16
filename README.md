# ⚡ ExDesk

<p align="center">
  <p align="center">
    <strong>The Open Source Service Desk & Asset Management Solution.</strong>
    <br />
    Built with Elixir and Phoenix for speed, reliability, and real-time performance.
  </p>
</p>

<p align="center">
  <a href="https://github.com/ExDesk/ExDesk/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/ExDesk/ExDesk.svg?style=flat-square" alt="Contributors" />
  </a>
  <a href="https://github.com/ExDesk/ExDesk/stargazers">
    <img src="https://img.shields.io/github/stars/ExDesk/ExDesk.svg?style=flat-square" alt="Stars" />
  </a>
  <a href="https://github.com/ExDesk/ExDesk/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/ExDesk/ExDesk.svg?style=flat-square" alt="License" />
  </a>
  <a href="https://elixir-lang.org/">
    <img src="https://img.shields.io/badge/Made%20with-Elixir-purple.svg?style=flat-square&logo=elixir" alt="Made with Elixir" />
  </a>
</p>

---

## 📖 About ExDesk

**ExDesk** is an open-source **IT Service Management (ITSM)** platform designed to unify **Help Desk** operations and **IT Asset Management** into a single, cohesive interface.

Think of it as **Zendesk meets Snipe-IT**, but built on the **BEAM (Erlang VM)**.

Current ITSM solutions are often resource-heavy, expensive, or lack seamless integration between tickets and hardware assets. ExDesk solves this by leveraging **Elixir** and **Phoenix LiveView** to provide a fault-tolerant, highly concurrent, and real-time experience without the bloat.

### 🚀 Why ExDesk?

* **⚡ High Performance:** Designed to handle thousands of concurrent connections with low memory footprint.
* **🔄 Real-Time:** Instant updates on ticket status, chats, and asset tracking using Phoenix Channels.
* **🛡️ Fault Tolerant:** Built on the battle-tested Erlang OTP ecosystem.
* **💸 Open Source:** No per-agent licensing fees. You own your data.

---

## ✨ Key Features

### 🎫 Help Desk (Issue Tracking)
* **Ticket Management:** Organize support requests with customizable statuses, priorities, and tags.
* **SLA Tracking:** Set and monitor Service Level Agreements to ensure timely responses.
* **Knowledge Base:** Markdown-supported articles to help users help themselves.
* **Multi-Channel:** Receive tickets via Email, API, or Web Interface.

### 📦 Asset Management (ITAM)
* **Inventory Tracking:** Manage hardware (laptops, mobiles) and software licenses.
* **Lifecycle Management:** Track assets from procurement to deployment and retirement.
* **Ticket Integration:** Link specific assets to support tickets for faster context and resolution.
* **Check-in/Check-out:** Assign assets to users with history logging.

---

## 🛠️ Tech Stack

* **Language:** [Elixir](https://elixir-lang.org/)
* **Framework:** [Phoenix Framework](https://www.phoenixframework.org/)
* **Database:** PostgreSQL
* **Frontend:** Phoenix LiveView (Server-side rendering with real-time capabilities) & Tailwind CSS

---

## 💻 Getting Started

### Prerequisites
* Elixir 1.14+
* Erlang/OTP 25+
* PostgreSQL 12+

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/ExDesk/ExDesk.git](https://github.com/ExDesk/ExDesk.git)
    cd ExDesk
    ```

2.  **Install dependencies:**
    ```bash
    mix deps.get
    ```

3.  **Setup the database:**
    Make sure your Postgres service is running and configured in `config/dev.exs`.
    ```bash
    mix ecto.setup
    ```

4.  **Start the Phoenix server:**
    ```bash
    mix phx.server
    ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

---

## 🛣️ Roadmap

- [ ] Core Ticket Management System
- [ ] Asset CRUD & Database Schema
- [ ] User Authentication & Roles (Admin, Agent, User)
- [ ] Linking Assets to Tickets
- [ ] Email Integration (Incoming/Outgoing)
- [ ] API for external integrations
- [ ] Docker Support

---

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

See `CONTRIBUTING.md` for more details.

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  Made with ❤️ by the <a href="https://github.com/ExDesk">ExDesk Team</a>.
</p>