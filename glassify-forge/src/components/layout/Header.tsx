import { Search, ShoppingBag, User, Menu } from "lucide-react";
import { GlassButton } from "@/components/ui/glass-button";
import { Input } from "@/components/ui/input";
import { Link } from "react-router-dom";

const Header = () => {
  return (
    <header className="sticky top-0 z-50 glass border-b border-glass-border/30 backdrop-blur-glass">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        {/* Logo */}
        <div className="flex items-center space-x-2">
          <Link to="/" className="text-hero text-2xl font-black">
            Veered
          </Link>
        </div>

        {/* Search Bar - Hidden on mobile */}
        <div className="hidden md:flex flex-1 max-w-md mx-8">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
            <Input
              placeholder="Search products, brands, or shops..."
              className="pl-10 glass border-glass-border/30 bg-glass-overlay/50 backdrop-blur-glass"
            />
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center space-x-2">
          {/* Mobile Menu */}
          <GlassButton variant="ghost" size="icon" className="md:hidden">
            <Menu className="h-5 w-5" />
          </GlassButton>

          {/* Mobile Search */}
          <GlassButton variant="ghost" size="icon" className="md:hidden">
            <Search className="h-5 w-5" />
          </GlassButton>

          {/* Shopping Bag */}
          <GlassButton variant="glass" size="icon" className="relative">
            <ShoppingBag className="h-5 w-5" />
            <span className="absolute -top-2 -right-2 bg-gradient-primary text-primary-foreground text-xs rounded-full h-5 w-5 flex items-center justify-center">
              3
            </span>
          </GlassButton>

          {/* Figma MCP */}
          <GlassButton asChild variant="hero" className="hidden md:inline-flex">
            <Link to="/figma">Figma MCP</Link>
          </GlassButton>

          {/* MCP Studio */}
          <GlassButton asChild variant="glass" className="hidden lg:inline-flex">
            <Link to="/mcp">MCP Studio</Link>
          </GlassButton>

          {/* User Profile */}
          <GlassButton variant="hero" size="icon">
            <User className="h-5 w-5" />
          </GlassButton>
        </div>
      </div>
    </header>
  );
};

export default Header;