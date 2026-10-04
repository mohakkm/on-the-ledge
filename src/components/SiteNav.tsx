import Link from "next/link";

const links = [
  { href: "/", label: "Dashboard" },
  { href: "/transactions", label: "Transactions" },
  { href: "/add-expense", label: "Add Expense" },
];

export function SiteNav() {
  return (
    <nav className="site-nav">
      <strong>On-the-ledge</strong>
      <ul>
        {links.map((link) => (
          <li key={link.href}>
            <Link href={link.href}>{link.label}</Link>
          </li>
        ))}
      </ul>
      <span className="nav-user">Demo user: Aarav (user_id = 1)</span>
    </nav>
  );
}
