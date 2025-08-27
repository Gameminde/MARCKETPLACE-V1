import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";
import { motion } from "framer-motion";

const neonCardVariants = cva(
  "relative rounded-xl backdrop-blur-xl border transition-all duration-300 overflow-hidden group",
  {
    variants: {
      variant: {
        default: "bg-surface/50 border-primary/20 hover:border-primary/40 hover:shadow-glow",
        electric: "bg-gradient-to-br from-primary/10 to-secondary/10 border-secondary/30 hover:border-secondary/60 hover:shadow-neon",
        cyber: "bg-surface/80 border-accent/30 hover:border-accent/60 hover:shadow-lg hover:shadow-accent/20",
        plasma: "bg-gradient-mesh border-transparent shadow-3d hover:shadow-glow animate-pulse",
        holographic: "bg-gradient-glass border-primary/20 hover:border-primary/60 hover:shadow-glow backdrop-blur-3xl",
      },
      size: {
        sm: "p-4",
        default: "p-6",
        lg: "p-8",
        xl: "p-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface NeonCardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof neonCardVariants> {
  floating?: boolean;
}

const NeonCard = React.forwardRef<HTMLDivElement, NeonCardProps>(
  ({ className, variant, size, floating = false, children, onDrag, onDragStart, onDragEnd, onDragOver, onDragEnter, onDragLeave, onDrop, onAnimationStart, onAnimationEnd, onAnimationIteration, ...props }, ref) => {
    return (
      <motion.div
        className={cn(neonCardVariants({ variant, size, className }))}
        ref={ref}
        whileHover={{ 
          y: floating ? -8 : -2,
          rotateX: floating ? 5 : 0,
          rotateY: floating ? 5 : 0,
        }}
        whileTap={{ scale: 0.98 }}
        transition={{
          type: "spring",
          stiffness: 300,
          damping: 20,
        }}
        style={{
          transformStyle: "preserve-3d",
        }}
        {...props}
      >
        {/* Animated border glow */}
        <div className="absolute inset-0 rounded-xl bg-gradient-neon opacity-0 group-hover:opacity-30 transition-opacity duration-500 blur-sm" />
        
        {/* Holographic effect */}
        <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-white/5 via-transparent to-white/5 opacity-50" />
        
        {/* Scanning line effect */}
        <div className="absolute top-0 left-0 w-full h-0.5 bg-gradient-to-r from-transparent via-primary to-transparent opacity-0 group-hover:opacity-100 group-hover:animate-pulse" />
        
        {/* Content */}
        <div className="relative z-10">
          {children}
        </div>
        
        {/* Corner decorations */}
        <div className="absolute top-2 left-2 w-4 h-4 border-l-2 border-t-2 border-primary/40 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        <div className="absolute top-2 right-2 w-4 h-4 border-r-2 border-t-2 border-primary/40 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        <div className="absolute bottom-2 left-2 w-4 h-4 border-l-2 border-b-2 border-primary/40 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        <div className="absolute bottom-2 right-2 w-4 h-4 border-r-2 border-b-2 border-primary/40 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
      </motion.div>
    );
  }
);
NeonCard.displayName = "NeonCard";

const NeonCardHeader = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex flex-col space-y-1.5 pb-4", className)}
    {...props}
  />
));
NeonCardHeader.displayName = "NeonCardHeader";

const NeonCardTitle = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLHeadingElement>
>(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn(
      "text-xl font-bold leading-none tracking-tight bg-gradient-primary bg-clip-text text-transparent",
      className
    )}
    {...props}
  />
));
NeonCardTitle.displayName = "NeonCardTitle";

const NeonCardDescription = React.forwardRef<
  HTMLParagraphElement,
  React.HTMLAttributes<HTMLParagraphElement>
>(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn("text-sm text-muted-foreground/80", className)}
    {...props}
  />
));
NeonCardDescription.displayName = "NeonCardDescription";

const NeonCardContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("", className)} {...props} />
));
NeonCardContent.displayName = "NeonCardContent";

const NeonCardFooter = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement>
>(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex items-center pt-4", className)}
    {...props}
  />
));
NeonCardFooter.displayName = "NeonCardFooter";

export {
  NeonCard,
  NeonCardHeader,
  NeonCardFooter,
  NeonCardTitle,
  NeonCardDescription,
  NeonCardContent,
  neonCardVariants,
};