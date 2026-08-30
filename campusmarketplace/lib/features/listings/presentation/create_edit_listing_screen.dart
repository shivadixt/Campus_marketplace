import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/listing_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/listings_provider.dart';

class CreateEditListingScreen extends ConsumerStatefulWidget {
  final Listing? existingListing;

  const CreateEditListingScreen({super.key, this.existingListing});

  @override
  ConsumerState<CreateEditListingScreen> createState() => _CreateEditListingScreenState();
}

class _CreateEditListingScreenState extends ConsumerState<CreateEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = AppConstants.categories.first;
  String _selectedCondition = AppConstants.conditions[2]; // Default 'Good'

  final List<XFile> _newSelectedImages = [];
  final List<String> _retainedImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  double _uploadProgress = 0.0;
  String _progressStatus = '';

  bool get isEditMode {
    return widget.existingListing != null;
  }

  int get totalImageCount {
    return _retainedImageUrls.length + _newSelectedImages.length;
  }

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final listing = widget.existingListing!;
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;

      if (listing.price % 1 == 0) {
        _priceController.text = listing.price.toInt().toString();
      } else {
        _priceController.text = listing.price.toString();
      }

      _locationController.text = listing.location;
      _selectedCategory = listing.category;
      _selectedCondition = listing.condition;
      _retainedImageUrls.addAll(listing.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Image picker
  Future<void> _pickImages(ImageSource source) async {
    final availableSlots = AppConstants.maxListingImages - totalImageCount;
    if (availableSlots <= 0) {
      _showSnackBar('Maximum of ${AppConstants.maxListingImages} photos allowed.');
      return;
    }

    try {
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          setState(() {
            _newSelectedImages.add(photo);
          });
        }
      } else {
        final photos = await _picker.pickMultiImage(limit: availableSlots);
        if (photos.isNotEmpty) {
          final toAdd = photos.take(availableSlots).toList();
          setState(() {
            _newSelectedImages.addAll(toAdd);
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to select photo: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _retainedImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
    });
  }

  // Save listing
  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (totalImageCount < AppConstants.minListingImages) {
      _showSnackBar('Please attach at least 1 photo of your item.');
      return;
    }

    final userProfile = ref.read(currentUserProfileProvider).value;
    final authUser = ref.read(authStateProvider).value;

    String activeUserId = '';
    if (userProfile != null) {
      activeUserId = userProfile.id;
    } else if (authUser != null) {
      activeUserId = authUser.uid;
    }

    if (activeUserId.isEmpty) {
      _showSnackBar('You must be logged in to create a listing.');
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
      _progressStatus = 'Preparing images...';
    });

    final repo = ref.read(listingsRepositoryProvider);
    final price = double.parse(_priceController.text.trim());

    String sellerDisplayName = 'Campus Student';
    if (userProfile != null) {
      if (userProfile.name.isNotEmpty) {
        sellerDisplayName = userProfile.name;
      }
    } else if (authUser != null) {
      if (authUser.displayName != null) {
        if (authUser.displayName!.isNotEmpty) {
          sellerDisplayName = authUser.displayName!;
        }
      }
    }

    String sellerPhoto = '';
    if (userProfile != null) {
      if (userProfile.photoUrl.isNotEmpty) {
        sellerPhoto = userProfile.photoUrl;
      }
    } else if (authUser != null) {
      if (authUser.photoURL != null) {
        sellerPhoto = authUser.photoURL!;
      }
    }

    String sellerPhone = '';
    if (userProfile != null) {
      if (userProfile.phone.isNotEmpty) {
        sellerPhone = userProfile.phone;
      }
    }

    try {
      if (isEditMode) {
        await repo.updateListing(
          existingListing: widget.existingListing!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
          condition: _selectedCondition,
          location: _locationController.text.trim(),
          retainedImageUrls: _retainedImageUrls,
          newImages: _newSelectedImages,
          onProgress: (progress, status) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
                _progressStatus = status;
              });
            }
          },
        );
      } else {
        await repo.createListing(
          sellerId: activeUserId,
          sellerName: sellerDisplayName,
          sellerPhone: sellerPhone,
          sellerPhotoUrl: sellerPhoto,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
          condition: _selectedCondition,
          location: _locationController.text.trim(),
          images: _newSelectedImages,
          onProgress: (progress, status) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
                _progressStatus = status;
              });
            }
          },
        );
      }

      if (mounted) {
        Navigator.pop(context);
        String successMessage = 'Listing published to campus!';
        if (isEditMode) {
          successMessage = 'Listing updated successfully!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to save listing: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String screenTitle = 'Create Listing';
    String submitButtonText = 'Publish Listing';

    if (isEditMode) {
      screenTitle = 'Edit Listing';
      submitButtonText = 'Save Changes';
    }

    if (_isSaving) {
      submitButtonText = 'Uploading & Publishing...';
    }

    VoidCallback? onSaveAction = _saveListing;
    if (_isSaving) {
      onSaveAction = null;
    }

    double? progressIndicatorValue;
    if (_uploadProgress > 0) {
      progressIndicatorValue = _uploadProgress;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(screenTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photos section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Item Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$totalImageCount / ${AppConstants.maxListingImages}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Photos are automatically compressed client-side before upload to preserve data.',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 12),

                  _buildPhotoSelector(),
                  const SizedBox(height: 24),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) {
                      return Validators.validateRequired(v, 'Title');
                    },
                    decoration: const InputDecoration(
                      labelText: 'Listing Title *',
                      hintText: 'e.g., Casio FX-991EX Scientific Calculator',
                      prefixIcon: Icon(Icons.sell_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price and category
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: Validators.validatePrice,
                          decoration: const InputDecoration(
                            labelText: 'Price (₹) *',
                            hintText: '450',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          items: AppConstants.categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(AppConstants.getCategoryIcon(cat), size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(cat, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Condition
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Item Condition *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppConstants.conditions.map((cond) {
                          final isSelected = _selectedCondition == cond;

                          Color textColor = AppColors.textPrimary;
                          FontWeight textWeight = FontWeight.w500;
                          Color borderColor = AppColors.border;

                          if (isSelected) {
                            textColor = Colors.white;
                            textWeight = FontWeight.w600;
                            borderColor = AppColors.primary;
                          }

                          return ChoiceChip(
                            label: Text(cond),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              color: textColor,
                              fontWeight: textWeight,
                            ),
                            side: BorderSide(color: borderColor),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCondition = cond;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      return Validators.validateRequired(v, 'Campus Location');
                    },
                    decoration: const InputDecoration(
                      labelText: 'Location on Campus *',
                      hintText: 'e.g., Hostel Block B / CS Dept',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    validator: (v) {
                      return Validators.validateRequired(v, 'Description');
                    },
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Mention details like age, condition notes, pickup spot...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Upload progress
                  if (_isSaving) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight.withAlpha(50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _progressStatus,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progressIndicatorValue,
                            backgroundColor: Colors.white,
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Submit button
                  ElevatedButton(
                    onPressed: onSaveAction,
                    child: Text(submitButtonText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (totalImageCount < AppConstants.maxListingImages)
            Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showImageSourceDialog,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.primary),
                      SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ...List.generate(_retainedImageUrls.length, (index) {
            final url = _retainedImageUrls[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 100,
                      height: 105,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        _removeExistingImage(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          ...List.generate(_newSelectedImages.length, (index) {
            final file = _newSelectedImages[index];

            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(file.path),
                      width: 100,
                      height: 105,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        _removeNewImage(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                  title: const Text('Take a picture with Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
