import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;
  final double width;

  const GameCard({super.key, required this.game, this.onTap, this.width = 160});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: game.thumbnailUrl,
                width: width,
                height: width,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: width,
                  height: width,
                  color: Colors.grey[200],
                  child: const Icon(Icons.gamepad, size: 32, color: Colors.grey),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: width,
                  height: width,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image,
                      size: 32, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              game.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  game.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
