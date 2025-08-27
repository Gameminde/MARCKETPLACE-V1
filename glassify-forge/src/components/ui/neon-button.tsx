import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";
import { motion } from "framer-motion";

const neonButtonVariants = cva(
  "relative inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-xl text-sm font-bold transition-all duration-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary disabled:pointer-events-none disabled:opacity-50 overflow-hidden group",
  {
    variants: {
      variant: {
        neon: "bg-gradient-primary text-primary-foreground shadow-neon hover:shadow-glow hover:scale-105 border border-primary/30",
        electric: "bg-gradient-secondary text-secondary-foreground shadow-lg hover:shadow-neon hover:scale-105 border border-secondary/30",
        cyber: "bg-surface border-2 border-primary text-primary hover:bg-primary hover:text-primary-foreground hover:shadow-glow hover:scale-105",
        ghost: "text-primary hover:bg-primary/10 hover:text-primary hover:shadow-glow border border-primary/20",
        plasma: "bg-gradient-neon text-foreground shadow-3d hover:shadow-glow hover:scale-110 animate-pulse",
      },
      size: {
        sm: "h-9 px-4 py-2 text-xs",
        default: "h-12 px-6 py-3",
        lg: "h-14 px-8 py-4 text-base",
        xl: "h-16 px-10 py-5 text-lg",
        icon: "h-12 w-12",
      },
    },
    defaultVariants: {
      variant: "neon",
      size: "default",
    },
  }
);

export interface NeonButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof neonButtonVariants> {
  asChild?: boolean;
}

const NeonButton = React.forwardRef<HTMLButtonElement, NeonButtonProps>(
  ({ className, variant, size, asChild = false, children, onDrag, onDragStart, onDragEnd, onDragOver, onDragEnter, onDragLeave, onDrop, onAnimationStart, onAnimationEnd, onAnimationIteration, ...props }, ref) => {
    const Comp = asChild ? Slot : motion.button;
    
    return (
      <Comp
        className={cn(neonButtonVariants({ variant, size, className }))}
        ref={ref}
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        animate={{
          boxShadow: [
            "0 0 20px rgba(139, 92, 246, 0.3)",
            "0 0 40px rgba(139, 92, 246, 0.5)",
            "0 0 20px rgba(139, 92, 246, 0.3)",
          ],
        }}
        transition={{
          boxShadow: {
            duration: 2,
            repeat: Infinity,
          },
          scale: {
            duration: 0.2,
          },
        }}
        {...props}
      >
        {/* Animated background glow */}
        <div className="absolute inset-0 rounded-xl bg-gradient-neon opacity-0 group-hover:opacity-20 transition-opacity duration-300" />
        
        {/* Particle effect overlay */}
        <div className="absolute inset-0 rounded-xl overflow-hidden">
          <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
        </div>
        
        {/* Content */}
        <span className="relative z-10 flex items-center gap-2">
          {children}
        </span>
      </Comp>
    );
  }
);
NeonButton.displayName = "NeonButton";

export { NeonButton, neonButtonVariants };