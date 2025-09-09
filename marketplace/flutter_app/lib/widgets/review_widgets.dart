import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../core/config/app_constants.dart';
import '../services/review_system.dart';
import '../widgets/glassmorphic_container.dart';

/// Comprehensive review display widget
class ReviewWidget extends StatelessWidget {
  final ProductReview review;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;
  final bool showActions;

  const ReviewWidget({
    super.key,
    required this.review,
    this.onHelpful,
    this.onReport,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: review.userAvatarUrl != null
                      ? NetworkImage(review.userAvatarUrl!)
                      : null,
                  child: review.userAvatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: AppConstants.spacingS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              ),
                              child: const Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          _buildStarRating(review.rating.value),
                          const SizedBox(width: AppConstants.spacingS),
                          Text(
                            _formatDate(review.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Review title
            Text(
              review.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingS),
            
            // Review comment
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // Media attachments
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              _buildImageGallery(review.imageUrls),
            ],
            
            if (review.videoUrls.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              _buildVideoGallery(review.videoUrls),
            ],
            
            // Tags
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              Wrap(
                spacing: AppConstants.spacingS,
                children: review.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                )).toList(),
              ),
            ],
            
            // Actions
            if (showActions) ...[
              const SizedBox(height: AppConstants.spacingM),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onHelpful,
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: Text('Helpful (${review.helpfulCount})'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Report'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Owner response
            if (review.ownerResponseText != null) ...[
              const SizedBox(height: AppConstants.spacingM),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppConstants.spacingS),
                        Text(
                          'Shop Response',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        if (review.ownerResponseDate != null)
                          Text(
                            _formatDate(review.ownerResponseDate!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      review.ownerResponseText!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < imageUrls.length - 1 ? AppConstants.spacingS : 0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: Image.network(
                imageUrls[index],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoGallery(List<String> videoUrls) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < videoUrls.length - 1 ? AppConstants.spacingS : 0,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}

/// Review statistics widget
class ReviewStatsWidget extends StatelessWidget {
  final ReviewStats stats;
  final VoidCallback? onViewAll;

  const ReviewStatsWidget({
    super.key,
    required this.stats,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    _buildStarRating(stats.averageRating),
                    Text(
                      '${stats.totalReviews} reviews',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppConstants.spacingL),
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final rating = 5 - index;
                      final count = stats.ratingDistribution[rating] ?? 0;
                      final percentage = stats.getRatingPercentage(rating);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$rating',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                valueColor: const AlwaysStoppedAnimation(Colors.amber),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Text(
                              '$count',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            Row(
              children: [
                _buildStatChip(
                  'With Photos',
                  '${stats.totalWithPhotos}',
                  Icons.photo_camera,
                ),
                const SizedBox(width: AppConstants.spacingS),
                _buildStatChip(
                  'Verified',
                  '${stats.totalVerifiedPurchases}',
                  Icons.verified,
                ),
              ],
            ),
            
            if (onViewAll != null) ...[
              const SizedBox(height: AppConstants.spacingM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onViewAll,
                  child: const Text('View All Reviews'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppConstants.spacingS),
          Text('$value $label'),
        ],
      ),
    );
  }
}

/// Review submission form
class ReviewSubmissionForm extends StatefulWidget {
  final String productId;
  final ProductReview? existingReview;
  final VoidCallback? onSubmitted;

  const ReviewSubmissionForm({
    super.key,
    required this.productId,
    this.existingReview,
    this.onSubmitted,
  });

  @override
  State<ReviewSubmissionForm> createState() => _ReviewSubmissionFormState();
}

class _ReviewSubmissionFormState extends State<ReviewSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  
  ReviewRating _rating = ReviewRating.five;
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  List<String> _selectedTags = [];
  
  final List<String> _availableTags = [
    'quality', 'value', 'fast shipping', 'as described',
    'comfortable', 'durable', 'stylish', 'recommend'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _titleController.text = widget.existingReview!.title;
      _commentController.text = widget.existingReview!.comment;
      _rating = widget.existingReview!.rating;
      _selectedTags = List.from(widget.existingReview!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewSystem>(
      builder: (context, reviewSystem, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating selector
              Text(
                'Rating',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildRatingSelector(),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Review Title',
                  hintText: 'Summarize your review',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Comment field
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Review Comment',
                  hintText: 'Share your thoughts about this product',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a comment';
                  }
                  if (value.trim().length < 10) {
                    return 'Comment must be at least 10 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Media attachments
              Text(
                'Add Photos/Videos (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildMediaAttachments(),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Tags
              Text(
                'Tags (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildTagSelector(),
              
              const SizedBox(height: AppConstants.spacingXL),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: reviewSystem.isSubmitting ? null : _submitReview,
                  child: reviewSystem.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.existingReview != null ? 'Update Review' : 'Submit Review'),
                ),
              ),
              
              if (reviewSystem.errorMessage != null) ...[
                const SizedBox(height: AppConstants.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Expanded(
                        child: Text(
                          reviewSystem.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = rating <= _rating.value;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = ReviewRatingExtension.fromValue(rating);
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingS),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMediaAttachments() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_camera),
                label: Text('Add Photos (${_selectedImages.length})'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickVideos,
                icon: const Icon(Icons.videocam),
                label: Text('Add Videos (${_selectedVideos.length})'),
              ),
            ),
          ],
        ),
        
        if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._selectedImages.map((file) => _buildMediaPreview(file, true)),
                ..._selectedVideos.map((file) => _buildMediaPreview(file, false)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaPreview(File file, bool isImage) {
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.spacingS),
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: isImage
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: Colors.black,
                      child: const Icon(Icons.play_circle_filled, color: Colors.white),
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isImage) {
                    _selectedImages.remove(file);
                  } else {
                    _selectedVideos.remove(file);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: AppConstants.spacingS,
      runSpacing: AppConstants.spacingS,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTags.add(tag);
              } else {
                _selectedTags.remove(tag);
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _pickImages() {
    // In a real app, this would open image picker
    // For demo purposes, we'll just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker would open here')),
    );
  }

  void _pickVideos() {
    // In a real app, this would open video picker
    // For demo purposes, we'll just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video picker would open here')),
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final reviewSystem = Provider.of<ReviewSystem>(context, listen: false);
    
    bool success;
    if (widget.existingReview != null) {
      success = await reviewSystem.updateReview(
        reviewId: widget.existingReview!.id,
        productId: widget.productId,
        rating: _rating,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
        newImages: _selectedImages,
        newVideos: _selectedVideos,
        tags: _selectedTags,
      );
    } else {
      success = await reviewSystem.submitReview(
        productId: widget.productId,
        rating: _rating,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
        images: _selectedImages,
        videos: _selectedVideos,
        tags: _selectedTags,
      );
    }

    if (success && mounted) {
      widget.onSubmitted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingReview != null 
              ? 'Review updated successfully!' 
              : 'Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// Review listing screen
class ReviewListScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ReviewListScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  final ReviewFilter _filter = const ReviewFilter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReviewSystem.instance.loadProductReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.productName} Reviews'),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<ReviewSystem>(
        builder: (context, reviewSystem, child) {
          final reviews = reviewSystem.getProductReviews(widget.productId);
          final stats = reviewSystem.getReviewStats(widget.productId);
          final isLoading = reviewSystem.isLoading(widget.productId);

          if (isLoading && reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              children: [
                // Statistics
                if (stats != null) ...[
                  ReviewStatsWidget(stats: stats),
                  const SizedBox(height: AppConstants.spacingL),
                ],

                // Reviews list
                if (reviews.isEmpty)
                  const Center(
                    child: Text('No reviews yet'),
                  )
                else
                  ...reviews.map((review) => Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: ReviewWidget(
                      review: review,
                      onHelpful: () => reviewSystem.markReviewHelpful(
                        review.id, 
                        widget.productId,
                      ),
                      onReport: () => _reportReview(review),
                    ),
                  )),

                if (isLoading && reviews.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingM),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    // Implementation for filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter dialog would open here')),
    );
  }

  void _reportReview(ProductReview review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: const Text('Why are you reporting this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ReviewSystem.instance.reportReview(
                review.id, 
                widget.productId, 
                'Inappropriate content',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review reported')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}