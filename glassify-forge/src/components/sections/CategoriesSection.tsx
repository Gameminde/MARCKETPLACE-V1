import { 
  Smartphone, 
  Shirt, 
  Home, 
  Gamepad2, 
  Dumbbell, 
  Book,
  Palette,
  Watch
} from "lucide-react";
import { GlassCard, GlassCardContent } from "@/components/ui/glass-card";

const categories = [
  { id: 1, name: "Electronics", icon: Smartphone, count: "2.5K+", color: "text-blue-500" },
  { id: 2, name: "Fashion", icon: Shirt, count: "3.2K+", color: "text-pink-500" },
  { id: 3, name: "Home & Garden", icon: Home, count: "1.8K+", color: "text-green-500" },
  { id: 4, name: "Gaming", icon: Gamepad2, count: "950+", color: "text-purple-500" },
  { id: 5, name: "Sports", icon: Dumbbell, count: "1.2K+", color: "text-orange-500" },
  { id: 6, name: "Books", icon: Book, count: "800+", color: "text-amber-500" },
  { id: 7, name: "Art & Crafts", icon: Palette, count: "650+", color: "text-rose-500" },
  { id: 8, name: "Accessories", icon: Watch, count: "1.5K+", color: "text-cyan-500" }
];

const CategoriesSection = () => {
  return (
    <section className="py-20 px-4">
      <div className="container mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-hero mb-4">
            Explore by Category
          </h2>
          <p className="text-subtitle max-w-2xl mx-auto">
            Discover thousands of products across diverse categories, 
            carefully curated by our expert team.
          </p>
        </div>

        <div className="grid-responsive">
          {categories.map((category, index) => {
            const Icon = category.icon;
            return (
              <GlassCard 
                key={category.id} 
                variant="feature"
                className="group cursor-pointer animate-fade-in-up"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <GlassCardContent className="text-center">
                  <div className="mb-4 flex justify-center">
                    <div className="p-4 rounded-full bg-gradient-glass group-hover:scale-110 transition-transform duration-300">
                      <Icon className={`h-8 w-8 ${category.color}`} />
                    </div>
                  </div>
                  <h3 className="text-lg font-semibold text-foreground mb-2">
                    {category.name}
                  </h3>
                  <p className="text-sm text-muted-foreground">
                    {category.count} products
                  </p>
                </GlassCardContent>
              </GlassCard>
            );
          })}
        </div>
      </div>
    </section>
  );
};

export default CategoriesSection;