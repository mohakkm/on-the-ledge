export function formatInr(amount: number | string): string {
  const value = typeof amount === "string" ? Number(amount) : amount;
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 2,
  }).format(Number.isFinite(value) ? value : 0);
}

export function formatMonth(dateValue: Date | string): string {
  const date =
    typeof dateValue === "string" ? new Date(`${dateValue}T00:00:00`) : dateValue;
  return new Intl.DateTimeFormat("en-IN", {
    month: "long",
    year: "numeric",
  }).format(date);
}

export function toDateInputValue(dateValue: Date | string): string {
  if (typeof dateValue === "string") {
    return dateValue.slice(0, 10);
  }
  return dateValue.toISOString().slice(0, 10);
}
