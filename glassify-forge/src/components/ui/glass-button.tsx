import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const glassButtonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-lg text-sm font-medium transition-all duration-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-focus disabled:pointer-events-none disabled:opacity-50 backdrop-blur-glass",
  {
    variants: {
      variant: {
        hero: "btn-hero text-primary-foreground shadow-glow hover:scale-105 hover:shadow-premium",
        secondary: "btn-secondary text-secondary-foreground hover:scale-105",
        glass: "btn-glass text-foreground hover:scale-105 hover:shadow-glow",
        outline: "glass border-2 border-primary/20 text-primary hover:bg-primary/10 hover:border-primary/40",
        ghost: "text-foreground hover:bg-glass-overlay hover:backdrop-blur-glass",
        premium: "bg-gradient-primary text-primary-foreground shadow-premium hover:scale-105 hover:shadow-glow",
      },
      size: {
        sm: "h-9 px-4 py-2 text-xs",
        default: "h-11 px-6 py-3",
        lg: "h-12 px-8 py-4 text-base",
        xl: "h-14 px-10 py-5 text-lg",
        icon: "h-11 w-11",
      },
    },
    defaultVariants: {
      variant: "glass",
      size: "default",
    },
  }
);

export interface GlassButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof glassButtonVariants> {
  asChild?: boolean;
}

const GlassButton = React.forwardRef<HTMLButtonElement, GlassButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(glassButtonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
GlassButton.displayName = "GlassButton";

export { GlassButton, glassButtonVariants };