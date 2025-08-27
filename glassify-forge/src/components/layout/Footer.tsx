import { Facebook, Twitter, Instagram, Youtube, Mail, Phone, MapPin } from "lucide-react";
import { GlassButton } from "@/components/ui/glass-button";
import { Input } from "@/components/ui/input";

const Footer = () => {
  return (
    <footer className="bg-gradient-hero text-primary-foreground">
      <div className="container mx-auto px-4 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="space-y-4">
            <div className="text-2xl font-black text-white">
              Veered
            </div>
            <p className="text-primary-foreground/80 text-sm">
              Premium marketplace connecting buyers with unique products from creators worldwide.
            </p>
            <div className="flex space-x-3">
              <GlassButton variant="glass" size="icon" className="bg-white/10 hover:bg-white/20">
                <Facebook className="h-4 w-4" />
              </GlassButton>
              <GlassButton variant="glass" size="icon" className="bg-white/10 hover:bg-white/20">
                <Twitter className="h-4 w-4" />
              </GlassButton>
              <GlassButton variant="glass" size="icon" className="bg-white/10 hover:bg-white/20">
                <Instagram className="h-4 w-4" />
              </GlassButton>
              <GlassButton variant="glass" size="icon" className="bg-white/10 hover:bg-white/20">
                <Youtube className="h-4 w-4" />
              </GlassButton>
            </div>
          </div>

          {/* Quick Links */}
          <div className="space-y-4">
            <h3 className="font-semibold text-white">Quick Links</h3>
            <ul className="space-y-2 text-sm">
              {["About Us", "How It Works", "Pricing", "Features", "Support"].map((link) => (
                <li key={link}>
                  <a href="#" className="text-primary-foreground/80 hover:text-white transition-colors">
                    {link}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Categories */}
          <div className="space-y-4">
            <h3 className="font-semibold text-white">Categories</h3>
            <ul className="space-y-2 text-sm">
              {["Electronics", "Fashion", "Home & Garden", "Sports", "Books"].map((category) => (
                <li key={category}>
                  <a href="#" className="text-primary-foreground/80 hover:text-white transition-colors">
                    {category}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Newsletter */}
          <div className="space-y-4">
            <h3 className="font-semibold text-white">Stay Updated</h3>
            <p className="text-primary-foreground/80 text-sm">
              Subscribe to get special offers and updates.
            </p>
            <div className="space-y-3">
              <Input
                placeholder="Your email address"
                className="bg-white/10 border-white/20 text-white placeholder:text-white/60"
              />
              <GlassButton variant="glass" className="w-full bg-white/10 hover:bg-white/20">
                Subscribe
              </GlassButton>
            </div>
          </div>
        </div>

        {/* Contact Info */}
        <div className="border-t border-white/20 mt-12 pt-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="flex items-center space-x-3">
              <Mail className="h-5 w-5 text-secondary" />
              <span className="text-sm text-primary-foreground/80">support@veered.com</span>
            </div>
            <div className="flex items-center space-x-3">
              <Phone className="h-5 w-5 text-secondary" />
              <span className="text-sm text-primary-foreground/80">+1 (555) 123-4567</span>
            </div>
            <div className="flex items-center space-x-3">
              <MapPin className="h-5 w-5 text-secondary" />
              <span className="text-sm text-primary-foreground/80">San Francisco, CA</span>
            </div>
          </div>

          {/* Bottom Bar */}
          <div className="flex flex-col md:flex-row justify-between items-center space-y-4 md:space-y-0">
            <div className="text-sm text-primary-foreground/60">
              © 2024 Veered. All rights reserved.
            </div>
            <div className="flex space-x-6 text-sm">
              <a href="#" className="text-primary-foreground/80 hover:text-white transition-colors">
                Privacy Policy
              </a>
              <a href="#" className="text-primary-foreground/80 hover:text-white transition-colors">
                Terms of Service
              </a>
              <a href="#" className="text-primary-foreground/80 hover:text-white transition-colors">
                Cookie Policy
              </a>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;