import { Palette, Zap, Users, Minimize2, Globe } from "lucide-react";
import { GlassCard, GlassCardContent, GlassCardHeader, GlassCardTitle, GlassCardDescription } from "@/components/ui/glass-card";
import { GlassButton } from "@/components/ui/glass-button";
import { Badge } from "@/components/ui/badge";

const templates = [
  {
    id: 1,
    name: "Feminine Elegance",
    description: "Soft curves, pastel colors, and elegant typography perfect for beauty, fashion, and lifestyle brands.",
    icon: Palette,
    colors: ["#F472B6", "#FDE2E7", "#FFFFFF"],
    features: ["Soft gradients", "Script fonts", "Generous spacing"],
    style: "Romantic & Sophisticated",
    preview: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop"
  },
  {
    id: 2,
    name: "Masculine Power",
    description: "Bold lines, dark tones, and strong typography designed for tech, automotive, and professional services.",
    icon: Zap,
    colors: ["#000000", "#374151", "#475569"],
    features: ["Bold typography", "Sharp edges", "Compact layout"],
    style: "Strong & Professional",
    preview: "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=400&h=300&fit=crop"
  },
  {
    id: 3,
    name: "Urban Street",
    description: "Vibrant colors, asymmetric layouts, and street-inspired design for creative and youth-oriented brands.",
    icon: Users,
    colors: ["#F97316", "#FDE047", "#0F172A"],
    features: ["Graffiti elements", "Asymmetric grid", "Bold contrasts"],
    style: "Creative & Energetic",
    preview: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop"
  },
  {
    id: 4,
    name: "Minimal Clean",
    description: "Pure simplicity with white space, clean lines, and minimal color palette for premium and luxury brands.",
    icon: Minimize2,
    colors: ["#FFFFFF", "#F8FAFC", "#000000"],
    features: ["White space", "Thin typography", "Geometric shapes"],
    style: "Clean & Luxurious",
    preview: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop"
  },
  {
    id: 5,
    name: "Neutral Balance",
    description: "Harmonious colors and balanced layouts suitable for any business type and target audience.",
    icon: Globe,
    colors: ["#6366F1", "#8B5CF6", "#10B981"],
    features: ["Balanced design", "System fonts", "Universal appeal"],
    style: "Versatile & Balanced",
    preview: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=300&fit=crop"
  }
];

const ShopTemplates = () => {
  return (
    <section className="py-20 px-4">
      <div className="container mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-hero mb-4">
            Customize Your Shop
          </h2>
          <p className="text-subtitle max-w-2xl mx-auto">
            Choose from our premium shop templates designed to match your brand identity 
            and connect with your target audience.
          </p>
        </div>

        <div className="grid-shop-templates">
          {templates.map((template, index) => {
            const Icon = template.icon;
            return (
              <GlassCard 
                key={template.id}
                variant="template"
                className="animate-fade-in-up"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <GlassCardHeader>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="p-2 rounded-lg bg-gradient-glass">
                        <Icon className="h-6 w-6 text-primary" />
                      </div>
                      <div>
                        <GlassCardTitle className="text-xl">
                          {template.name}
                        </GlassCardTitle>
                        <Badge variant="secondary" className="text-xs">
                          {template.style}
                        </Badge>
                      </div>
                    </div>
                  </div>
                </GlassCardHeader>

                <GlassCardContent>
                  {/* Preview Image */}
                  <div className="relative mb-6 rounded-lg overflow-hidden">
                    <img
                      src={template.preview}
                      alt={`${template.name} template preview`}
                      className="w-full h-40 object-cover"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
                  </div>

                  {/* Color Palette */}
                  <div className="mb-4">
                    <div className="text-sm font-medium mb-2 text-foreground">Color Palette</div>
                    <div className="flex space-x-2">
                      {template.colors.map((color, colorIndex) => (
                        <div
                          key={colorIndex}
                          className="w-8 h-8 rounded-full border-2 border-white shadow-md"
                          style={{ backgroundColor: color }}
                        />
                      ))}
                    </div>
                  </div>

                  {/* Description */}
                  <GlassCardDescription className="mb-4">
                    {template.description}
                  </GlassCardDescription>

                  {/* Features */}
                  <div className="space-y-2">
                    <div className="text-sm font-medium text-foreground">Key Features</div>
                    <div className="flex flex-wrap gap-2">
                      {template.features.map((feature, featureIndex) => (
                        <Badge key={featureIndex} variant="outline" className="text-xs">
                          {feature}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </GlassCardContent>

                <div className="mt-6 space-y-3">
                  <GlassButton variant="hero" className="w-full">
                    Preview Template
                  </GlassButton>
                  <GlassButton variant="outline" className="w-full">
                    Use This Template
                  </GlassButton>
                </div>
              </GlassCard>
            );
          })}
        </div>

        {/* Call to Action */}
        <div className="text-center mt-16 glass-card p-8">
          <h3 className="text-2xl font-bold mb-4 text-foreground">
            Ready to Launch Your Shop?
          </h3>
          <p className="text-muted-foreground mb-6 max-w-md mx-auto">
            Join thousands of successful sellers who have built their brand with our platform.
          </p>
          <GlassButton variant="premium" size="lg">
            Start Selling Today
          </GlassButton>
        </div>
      </div>
    </section>
  );
};

export default ShopTemplates;