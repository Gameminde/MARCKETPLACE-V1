import { Star, Heart, ShoppingCart } from "lucide-react";
import { GlassCard, GlassCardContent, GlassCardFooter } from "@/components/ui/glass-card";
import { GlassButton } from "@/components/ui/glass-button";
import { Badge } from "@/components/ui/badge";

const products = [
  {
    id: 1,
    name: "Premium Wireless Headphones",
    price: 299,
    originalPrice: 399,
    rating: 4.8,
    reviews: 1250,
    image: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop",
    badge: "Bestseller",
    seller: "AudioTech Pro"
  },
  {
    id: 2,
    name: "Minimalist Smart Watch",
    price: 199,
    rating: 4.6,
    reviews: 890,
    image: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop",
    badge: "New",
    seller: "WearTech"
  },
  {
    id: 3,
    name: "Organic Cotton T-Shirt",
    price: 45,
    originalPrice: 65,
    rating: 4.9,
    reviews: 2100,
    image: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop",
    badge: "Eco-Friendly",
    seller: "GreenWear Co"
  },
  {
    id: 4,
    name: "Professional Camera Lens",
    price: 899,
    rating: 4.7,
    reviews: 456,
    image: "https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=400&h=400&fit=crop",
    badge: "Pro",
    seller: "LensStudio"
  },
  {
    id: 5,
    name: "Artisan Coffee Beans",
    price: 24,
    rating: 4.8,
    reviews: 1890,
    image: "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&h=400&fit=crop",
    badge: "Limited",
    seller: "BrewMasters"
  },
  {
    id: 6,
    name: "Designer Handbag",
    price: 156,
    originalPrice: 220,
    rating: 4.5,
    reviews: 678,
    image: "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=400&fit=crop",
    badge: "Sale",
    seller: "LuxBags"
  }
];

const FeaturedProducts = () => {
  return (
    <section className="py-20 px-4 bg-surface/50">
      <div className="container mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-hero mb-4">
            Featured Products
          </h2>
          <p className="text-subtitle max-w-2xl mx-auto">
            Handpicked products from our premium sellers, 
            featuring the latest trends and highest quality items.
          </p>
        </div>

        <div className="grid-responsive">
          {products.map((product, index) => (
            <GlassCard 
              key={product.id}
              variant="default"
              className="group animate-fade-in-up"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <GlassCardContent className="space-y-4">
                {/* Product Image */}
                <div className="relative overflow-hidden rounded-lg">
                  <img
                    src={product.image}
                    alt={product.name}
                    className="w-full h-48 object-cover transition-transform duration-300 group-hover:scale-105"
                  />
                  {/* Badge */}
                  <Badge 
                    className="absolute top-3 left-3 bg-gradient-primary text-primary-foreground"
                  >
                    {product.badge}
                  </Badge>
                  {/* Wishlist */}
                  <GlassButton
                    variant="glass"
                    size="icon"
                    className="absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  >
                    <Heart className="h-4 w-4" />
                  </GlassButton>
                </div>

                {/* Product Info */}
                <div className="space-y-2">
                  <div className="text-xs text-muted-foreground">
                    by {product.seller}
                  </div>
                  <h3 className="font-semibold text-foreground line-clamp-2">
                    {product.name}
                  </h3>
                  
                  {/* Rating */}
                  <div className="flex items-center space-x-2">
                    <div className="flex items-center space-x-1">
                      <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                      <span className="text-sm font-medium">{product.rating}</span>
                    </div>
                    <span className="text-xs text-muted-foreground">
                      ({product.reviews.toLocaleString()} reviews)
                    </span>
                  </div>

                  {/* Price */}
                  <div className="flex items-center space-x-2">
                    <span className="text-lg font-bold text-primary">
                      ${product.price}
                    </span>
                    {product.originalPrice && (
                      <span className="text-sm text-muted-foreground line-through">
                        ${product.originalPrice}
                      </span>
                    )}
                  </div>
                </div>
              </GlassCardContent>

              <GlassCardFooter>
                <GlassButton variant="glass" size="sm" className="flex-1">
                  <ShoppingCart className="h-4 w-4" />
                  Add to Cart
                </GlassButton>
              </GlassCardFooter>
            </GlassCard>
          ))}
        </div>

        {/* View All Button */}
        <div className="text-center mt-12">
          <GlassButton variant="hero" size="lg">
            View All Products
          </GlassButton>
        </div>
      </div>
    </section>
  );
};

export default FeaturedProducts;