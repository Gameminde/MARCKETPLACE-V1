# Assets Directory Structure

This directory contains all the assets used in the Marketplace mobile application.

## Directory Structure

### 📱 Icons (`icons/`)
- `navigation/` - Bottom navigation, app bar icons
- `actions/` - Action buttons, CRUD operations
- `categories/` - Product category icons
- `social/` - Social media, sharing icons
- `payment/` - Payment method icons
- `status/` - Order status, notification icons

### 🖼️ Images (`images/`)
- `products/` - Product images and thumbnails
- `categories/` - Category banner images
- `users/` - User avatars and profile images
- `backgrounds/` - App backgrounds, patterns
- `logos/` - Brand logos, shop logos
- `placeholders/` - Loading and empty state images

### 🎬 Animations (`animations/`)
- Loading animations
- Micro-interactions
- Page transitions

### 🎭 Lottie (`lottie/`)
- Complex animations in Lottie format
- Loading states
- Success/Error animations
- Empty state illustrations

### 🎮 Rive (`rive/`)
- Interactive animations
- Character animations
- Complex UI animations

### 🔊 Sounds (`sounds/`)
- Notification sounds
- Button click sounds
- Success/Error audio feedback

### 📊 Data (`data/`)
- JSON configuration files
- Mock data for development
- Localization files backup

## Asset Naming Convention

### Images
- Use lowercase with underscores: `product_thumbnail.png`
- Include density suffixes: `icon_cart@2x.png`, `icon_cart@3x.png`
- Use descriptive names: `category_electronics_banner.jpg`

### Icons
- SVG format preferred for scalability
- PNG with multiple densities as fallback
- Naming: `ic_action_name.svg`

### Animations
- Lottie: `animation_loading.json`
- Rive: `interactive_button.riv`

## File Formats

### Recommended Formats
- **Icons**: SVG (preferred), PNG
- **Images**: WebP (preferred), JPEG, PNG
- **Animations**: Lottie JSON, Rive files
- **Sounds**: MP3, AAC

### Size Guidelines
- **Icons**: 24dp, 32dp, 48dp base sizes
- **Images**: Optimize for mobile (< 500KB per image)
- **Animations**: Keep Lottie files under 100KB when possible

## Usage Examples

```dart
// Using images
Image.asset('assets/images/products/product_thumbnail.png')

// Using icons
SvgPicture.asset('assets/icons/navigation/ic_home.svg')

// Using Lottie animations
Lottie.asset('assets/lottie/animation_loading.json')

// Using Rive animations
RiveAnimation.asset('assets/rive/interactive_button.riv')
```

## Asset Optimization

1. **Image Compression**: Use tools like TinyPNG for JPEG/PNG compression
2. **WebP Format**: Convert to WebP for better compression
3. **SVG Optimization**: Use SVGO to optimize SVG files
4. **Lottie Optimization**: Use LottieFiles tools to reduce file size

## Notes

- All assets should be properly licensed for commercial use
- Maintain consistent visual style across all assets
- Regular cleanup of unused assets
- Document any external asset sources and licenses