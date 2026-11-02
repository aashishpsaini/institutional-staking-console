import { NavLink, Route, Routes } from "react-router-dom";
import OperationsPage from "./pages/OperationsPage";
import PortfolioPage from "./pages/PortfolioPage";
import RewardsPage from "./pages/RewardsPage";

export default function App() {
  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span>Institutional Staking</span>
          <span className="brand-badge">Console</span>
        </div>
        <nav>
          <NavLink to="/" end className={({ isActive }) => (isActive ? "active" : "")}>
            Portfolio
          </NavLink>
          <NavLink to="/rewards" className={({ isActive }) => (isActive ? "active" : "")}>
            Rewards
          </NavLink>
          <NavLink to="/operations" className={({ isActive }) => (isActive ? "active" : "")}>
            Operations
          </NavLink>
        </nav>
      </header>
      <main>
        <Routes>
          <Route path="/" element={<PortfolioPage />} />
          <Route path="/rewards" element={<RewardsPage />} />
          <Route path="/operations" element={<OperationsPage />} />
        </Routes>
      </main>
    </div>
  );
}
