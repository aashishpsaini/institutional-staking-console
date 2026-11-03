import { NavLink, Route, Routes } from "react-router-dom";
import { Alert } from "./components/Alert";
import { EmptyState } from "./components/EmptyState";
import { NetworksProvider, useNetworks } from "./hooks/useNetworks";
import OperationsPage from "./pages/OperationsPage";
import PortfolioPage from "./pages/PortfolioPage";
import RewardsPage from "./pages/RewardsPage";

const NAV = [
  { to: "/", label: "Portfolio" },
  { to: "/rewards", label: "Rewards" },
  { to: "/operations", label: "Operations" }
] as const;

function NetworksError() {
  const { error } = useNetworks();
  return error ? <Alert variant="error">Could not load network metadata: {error}</Alert> : null;
}

export default function App() {
  return (
    <NetworksProvider>
      <div className="app">
        <header className="topbar">
          <div className="brand">
            <span>Institutional Staking</span>
            <span className="brand-badge">Console</span>
          </div>
          <nav aria-label="Primary">
            {NAV.map(({ to, label }) => (
              <NavLink key={to} to={to} end={to === "/"}>
                {label}
              </NavLink>
            ))}
          </nav>
        </header>
        <main>
          <NetworksError />
          <Routes>
            <Route path="/" element={<PortfolioPage />} />
            <Route path="/rewards" element={<RewardsPage />} />
            <Route path="/operations" element={<OperationsPage />} />
            <Route path="*" element={<EmptyState message="Page not found." />} />
          </Routes>
        </main>
      </div>
    </NetworksProvider>
  );
}
