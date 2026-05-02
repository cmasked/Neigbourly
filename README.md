 <h1>Neighborly 🏡</h1>
  <p>
    <b>A premium, peer-to-peer rental network for isolated neighborhood communities.</b>
  </p>
  <p>
    Borrow that power drill, rent out your camping tent, or share the projector with verified members of your own residential community or society. Trust-based, community-driven, and built with modern tech.
  </p>

  <br />

  [![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
  [![Vue.js](https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vue.js&logoColor=4FC08D)](https://vuejs.org/)
  [![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)

</div>

<br />

## 🌟 The Vision

**Neighborly** brings the sharing economy back home. It allows gated communities, apartment complexes, and tech parks to have their own private "rental marketplaces". 

Rather than buying items you only use once a year, you can rent them for a fraction of the cost from your neighbor down the hall—secured by an automated Trust Score system and localized verification.

## 🚀 Features

- **Community Isolation**: Every user belongs to a specific Community (e.g., "Maple Heights Residency"). You only see items and requests from people inside your own verified neighborhood.
- **Cross-Platform Access**: Includes a beautifully crafted **Flutter Mobile Application** and a responsive **Vue.js Web Application**.
- **The "Curated Hearth" Aesthetic**: Stunning UI design featuring glassmorphism, golden-hour ambient shadows, and a unified platform backdrop.
- **Dynamic Trust Scores**: Users start with a base score that increases with good behavior (on-time returns, 5-star reviews) and decreases with disputes or late returns.
- **Escrow Payment Engine**: Funds are held in escrow on rental confirmation and automatically released to the owner via Celery workers upon return confirmation — neither party can be cheated.
- **Automated Workflow Engine**: Transactions follow a strict state machine (`pending` → `confirmed` → `picked_up` → `returned`).

## 🏗️ Technology Stack

### Backend
- **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Python 3.12)
- **Database**: MySQL 8.0 via `aiomysql` and Async SQLAlchemy 2.0
- **Caching & Queues**: Redis & Celery
- **Authentication**: JWT-based with bcrypt password hashing

### Frontend (Web)
- **Framework**: Vue 3 (Composition API via CDN)
- **Styling**: TailwindCSS & custom vanilla CSS for glassmorphic effects

### Mobile App (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: Riverpod (`flutter_riverpod`)
- **Networking**: Dio with advanced Auth Interceptors
- **Storage**: `SharedPreferences` (Web/Desktop) and `FlutterSecureStorage` (Mobile)

---

## 🛠️ Getting Started Locally

### Prerequisites
- Docker & Docker Compose
- Python 3.12+
- Flutter SDK (for mobile app)

### 1. Start the Database
The backend requires MySQL and Redis. Start them via docker:
```bash
docker-compose up -d
```
*(Note: On first boot, this will automatically seed dummy communities, users, and items via `sql/schema.sql` and `sql/seed.sql`)*

### 2. Run the FastAPI Backend
Create a virtual environment, install dependencies, and run:
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Run the server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
The API and Web Frontend will now be available at `http://localhost:8000`.

### 3. Run the Flutter Mobile App
In a new terminal window, navigate to the mobile app directory:
```bash
cd neighborly_mobile
flutter pub get

# To run in Chrome (Web version of the mobile app)
flutter run -d chrome
```

## 📂 Project Structure

```text
Neighborly/
├── app/                  # FastAPI Backend codebase (Routers, Models, Schemas)
├── frontend/             # Vue.js Web Frontend (served directly by FastAPI)
├── neighborly_mobile/    # Flutter Mobile App source code
├── sql/                  # Docker DB initialization & seeding scripts
├── docker-compose.yml    # Infrastructure configuration
└── README.md
```

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/cmasked/Neigborly/issues).

## 📄 License
This project is licensed under the MIT License.
