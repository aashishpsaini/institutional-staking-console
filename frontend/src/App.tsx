import { Link, Route, Routes } from "react-router-dom";
import PortfolioPage from "./pages/PortfolioPage";
import RewardsPage from "./pages/RewardsPage";
import OperationsPage from "./pages/OperationsPage";

export default function App() {
  return (
    <div className="app">
      <header className="topbar">
        <strong>Institutional Staking Console</strong>
        <nav>
          <Link to="/">Portfolio</Link>
          <Link to="/rewards">Rewards</Link>
          <Link to="/operations">Operations</Link>
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
