export type { BaseButtonProps } from "./UnstalyedButton";

import { BaseButtonProps, UnstyledButton } from "./UnstalyedButton";
import { Spinner } from "./Spinner";
import { calcClassName } from "./calcClassNames";

export function PrimaryButton(props: BaseButtonProps) {
  const className = calcClassName(props, {
    always: "border border-accent-1",
    normal: "text-white-1 bg-accent-1 hover:bg-accent-1-light",
    loading: "text-content-subtle bg-accent-1-light",
  });

  return (
    <UnstyledButton
      {...props}
      className={className}
      spinner={<Spinner loading={props.loading} size={props.size} color="var(--color-white-1)" />}
    />
  );
}

export function DangerButton(props: BaseButtonProps) {
  const className = calcClassName(props, {
    always: "border border-red-500",
    normal: "text-white-1 bg-red-500 hover:bg-red-600 dark:hover:bg-red-400",
    loading: "text-content-subtle bg-red-400 dark:bg-red-500",
  });

  return (
    <UnstyledButton
      {...props}
      className={className}
      spinner={<Spinner loading={props.loading} size={props.size} color="var(--color-white-1)" />}
    />
  );
}

export function GhostButton(props: BaseButtonProps) {
  const className = calcClassName(props, {
    always: "border border-accent-1",
    loading: "text-content-subtle bg-accent-1-light",
    normal: "text-accent-1 hover:text-white-1 hover:bg-accent-1",
  });

  return (
    <UnstyledButton
      {...props}
      className={className}
      spinner={<Spinner loading={props.loading} color="var(--color-white-1)" size={props.size} />}
    />
  );
}

export function SecondaryButton(props: BaseButtonProps) {
  const className = calcClassName(props, {
    always: "border border-surface-outline bg-surface-base",
    normal: "text-content-dimmed hover:text-content-base hover:bg-surface-accent",
    loading: "text-content-subtle",
  });

  return (
    <UnstyledButton
      {...props}
      className={className}
      spinner={<Spinner loading={props.loading} size={props.size} color="var(--color-accent-1)" />}
    />
  );
}
