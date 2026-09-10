# Professional Design Guide for Tweyonje App

This guide provides best practices for creating a professional, polished user experience for the Tweyonje Smart Waste Management application.

## Visual Identity

### Brand Colors

The Tweyonje brand uses an eco-friendly color palette that reflects sustainability and cleanliness:

- **Primary**: Forest Green (#2E7D32) - Represents eco-friendliness and growth
- **Accent**: Amber (#FF6F00) - Represents energy and warmth
- **Success**: Green (#2E7D32) - For positive actions and success states
- **Warning**: Orange (#F57C00) - For cautionary states
- **Danger**: Red (#D32F2F) - For errors and destructive actions
- **Info**: Blue (#1976D2) - For informational content

### Typography

**Font Family**: System fonts (San Francisco on iOS, Roboto on Android)

**Hierarchy**:
- **Display**: 48px - Hero sections and major headings
- **H1**: 32px - Page titles
- **H2**: 24px - Section headings
- **H3**: 20px - Subsection headings
- **Body**: 16px - Primary content
- **Caption**: 12px - Supporting text

**Weight**:
- Regular (400) - Body text
- Medium (500) - Emphasized text
- Semibold (600) - Headings and buttons
- Bold (700) - Strong emphasis

## Icon Usage

### Icon Library

The app uses Ionicons for consistent, professional icons across all platforms.

### Icon Guidelines

**Size Standards**:
- **Small**: 16px - Inline icons, badges
- **Medium**: 24px - List items, buttons
- **Large**: 32px - Section headers, cards
- **Extra Large**: 48px - Empty states, featured content
- **Display**: 64px - Hero sections, major illustrations

**Color Usage**:
- Primary icons: Use brand colors (primary, accent)
- Neutral icons: Use text colors (text, textMuted, textLight)
- Semantic icons: Use semantic colors (success, warning, danger, info)
- Outlined icons: Use for inactive or secondary states
- Filled icons: Use for active or primary states

**Common Icon Mappings**:

| Function | Icon | Variant |
|----------|------|---------|
| Navigation | `arrow-back`, `chevron-forward`, `menu` | Outline |
| Actions | `add`, `checkmark`, `close` | Outline/Filled |
| User | `person`, `people`, `person-circle` | Outline |
| Location | `location`, `map`, `navigate` | Outline |
| Communication | `mail`, `call`, `chatbubbles` | Outline |
| Settings | `settings`, `cog`, `options` | Outline |
| Status | `checkmark-circle`, `alert-circle`, `information-circle` | Outline |
| Waste | `trash`, `recycle`, `cube` | Outline |
| Payment | `card`, `cash`, `wallet` | Outline |
| Time | `time`, `calendar`, `hourglass` | Outline |

### Icon Best Practices

1. **Consistency**: Use the same icon for the same action throughout the app
2. **Clarity**: Choose icons that are universally understood
3. **Spacing**: Maintain consistent padding around icons
4. **Alignment**: Center icons vertically with text
5. **Accessibility**: Add accessibility labels for screen readers

## Imagery Guidelines

### Image Standards

**Aspect Ratios**:
- **Square**: 1:1 - Profile photos, thumbnails
- **Portrait**: 3:4 - Cards, featured content
- **Landscape**: 16:9 - Hero images, banners
- **Wide**: 21:9 - Full-width banners

**Image Quality**:
- Minimum resolution: 2x for retina displays
- File format: WebP preferred, PNG for transparency
- File size: Compress to under 500KB per image
- Color profile: sRGB for consistent colors

### Image Categories

**1. Brand Assets**
- Logo: SVG format for scalability
- App icon: 1024x1024px PNG
- Splash screen: Platform-specific dimensions

**2. Illustrations**
- Empty states: Custom illustrations or icons
- Onboarding: Consistent illustration style
- Error states: Friendly, approachable imagery

**3. Photography**
- Waste management: Professional, clean images
- Community: Diverse, inclusive representation
- Environment: Natural, positive imagery

### Image Loading

**Best Practices**:
1. Use progressive loading for large images
2. Implement lazy loading for lists
3. Provide fallback images
4. Use appropriate placeholder colors
5. Optimize images for web/mobile

## Component Styling

### Cards

**Elevation Levels**:
- Default: Small shadow (elevation 2)
- Elevated: Medium shadow (elevation 4)
- Hover/Focus: Large shadow (elevation 8)

**Border Radius**:
- Small cards: 12px
- Medium cards: 16px
- Large cards: 20px
- Full cards: 24px

**Padding**:
- Compact: 12px
- Standard: 16px
- Spacious: 24px

### Buttons

**States**:
- Normal: Full color, medium shadow
- Pressed: 80% opacity, scale 0.98
- Disabled: 50% opacity
- Loading: Show spinner, hide text

**Variants**:
- Primary: Brand color, white text
- Secondary: Surface color, brand text
- Outline: Transparent, brand border
- Ghost: Transparent, brand text
- Danger: Red color, white text
- Success: Green color, white text

**Sizes**:
- Small: 40px height
- Medium: 50px height
- Large: 56px height

### Inputs

**States**:
- Normal: Border color, white background
- Focus: Brand border color, subtle shadow
- Error: Red border, light red background
- Disabled: 50% opacity

**Features**:
- Labels: Uppercase, semibold, letter-spacing
- Icons: 20px size, consistent spacing
- Helper text: Muted color, below input
- Error text: Red color, below input

## Layout Principles

### Spacing System

**Scale**:
- XS: 4px - Tight spacing
- SM: 8px - Small spacing
- MD: 16px - Standard spacing
- LG: 24px - Large spacing
- XL: 32px - Extra large spacing
- XXL: 48px - Section spacing

**Usage**:
- Component padding: MD to LG
- Section margins: LG to XL
- Page margins: XL to XXL
- Element gaps: SM to MD

### Grid System

**Columns**:
- Mobile: 1 column
- Tablet: 2 columns
- Desktop: 3-4 columns

**Gutter**:
- Mobile: 16px
- Tablet: 24px
- Desktop: 32px

## Animation Guidelines

### Duration Standards

- **Fast**: 150ms - Micro-interactions
- **Normal**: 300ms - Standard transitions
- **Slow**: 500ms - Complex animations

### Easing Functions

- **Ease In**: For entering from off-screen
- **Ease Out**: For exiting to off-screen
- **Ease In Out**: For in-place transitions
- **Spring**: For physical interactions

### Animation Types

**Screen Transitions**:
- Horizontal slide: Navigation between screens
- Vertical slide: Modal presentations
- Fade: Tab switching
- Zoom: Image galleries

**Element Animations**:
- Fade in: Content loading
- Slide up: Lists appearing
- Scale: Button presses
- Shake: Error states

## Accessibility

### Color Contrast

- Normal text: 4.5:1 contrast ratio minimum
- Large text: 3:1 contrast ratio minimum
- Interactive elements: 3:1 contrast ratio minimum

### Touch Targets

- Minimum size: 44x44px
- Recommended size: 48x48px
- Spacing: 8px between targets

### Screen Reader Support

- Add accessibility labels to all interactive elements
- Use semantic icons with meaningful labels
- Provide context for actions
- Announce state changes

## Responsive Design

### Breakpoints

- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

### Adaptations

- Font sizes scale with screen size
- Padding adjusts for larger screens
- Grid columns increase on larger screens
- Touch targets remain consistent

## Professional Tips

### Polish Details

1. **Subtle Shadows**: Use soft, multi-layered shadows for depth
2. **Smooth Transitions**: All interactions should feel natural
3. **Consistent Spacing**: Use the spacing system consistently
4. **Thoughtful Colors**: Use color purposefully, not randomly
5. **Clear Hierarchy**: Guide users through visual hierarchy
6. **Feedback**: Provide immediate feedback for all actions
7. **Loading States**: Show loading indicators for async actions
8. **Empty States**: Provide helpful empty states with actions
9. **Error Handling**: Show clear, actionable error messages
10. **Success States**: Celebrate successful actions with feedback

### Common Mistakes to Avoid

1. Inconsistent spacing
2. Too many colors
3. Hard-to-read text
4. Unclear icons
5. Missing loading states
6. No empty states
7. Vague error messages
8. Inconsistent button styles
9. Poor contrast ratios
10. Cluttered layouts

## Resources

### Design Tools
- Figma: UI design and prototyping
- Sketch: macOS design tool
- Adobe XD: Adobe design tool

### Icon Resources
- Ionicons: Primary icon library
- Material Icons: Alternative icon set
- Feather Icons: Minimalist icon set

### Image Resources
- Unsplash: Free stock photography
- Pexels: Free stock photos and videos
- Pixabay: Free images and illustrations

### Color Tools
- Coolors: Color palette generator
- Adobe Color: Color scheme creation
- Paletton: Color harmony tool

## Implementation Checklist

Before releasing any screen:

- [ ] Colors match brand guidelines
- [ ] Typography follows hierarchy
- [ ] Icons are consistent and meaningful
- [ ] Images are optimized and properly sized
- [ ] Spacing uses the spacing system
- [ ] Shadows are subtle and appropriate
- [ ] Animations are smooth and purposeful
- [ ] Loading states are implemented
- [ ] Empty states are helpful
- [ ] Error messages are clear
- [ ] Touch targets are properly sized
- [ ] Color contrast meets accessibility standards
- [ ] Screen reader labels are present
- [ ] Responsive design works on all sizes
- [ ] Overall feel is polished and professional
