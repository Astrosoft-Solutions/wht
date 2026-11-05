const inr = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 2 });

export const money = (amount) => (amount == null ? '-' : inr.format(amount).replace(/\.00$/, ''));

export const date = (iso) =>
  iso ? new Date(iso).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '-';

export const dateTime = (iso) =>
  iso
    ? new Date(iso).toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit' })
    : '-';

export const titleCase = (value) => (value ? value.charAt(0).toUpperCase() + value.slice(1) : '-');

export const COACH_TYPES = ['consultant', 'coach', 'guide'];
export const TIERS = ['gold', 'silver', 'bronze'];

export const TIER_STYLE = {
  gold: { color: '#B8860B', background: '#FFF4CC' },
  silver: { color: '#5F6B7A', background: '#ECEFF3' },
  bronze: { color: '#8C5A2B', background: '#F6E6D8' },
};

/** "08:00" -> "8:00 AM" */
export function time12(hhmm) {
  if (!hhmm) return '';
  const [h, m] = hhmm.split(':').map(Number);
  const suffix = h >= 12 ? 'PM' : 'AM';
  return `${((h + 11) % 12) + 1}:${String(m).padStart(2, '0')} ${suffix}`;
}

export const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

export function daysLabel(days) {
  if (!days || days.length === 0 || days.length === 7) return 'Every day';
  return [...days].sort().map((d) => WEEKDAYS[d - 1]).join(', ');
}
