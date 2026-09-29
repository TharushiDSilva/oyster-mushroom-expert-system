export default function SectionHeader({
  index,
  title,
  subtitle,
}: {
  index: string;
  title: string;
  subtitle?: string;
}) {
  return (
    <div className="mb-4 flex items-start gap-3">
      <span className="text-2xl font-extrabold leading-none text-accent tabular-nums">
        {index}
      </span>
      <div>
        <h2 className="text-base font-bold text-foreground sm:text-lg">{title}</h2>
        {subtitle && <p className="mt-0.5 text-sm text-muted">{subtitle}</p>}
      </div>
    </div>
  );
}
