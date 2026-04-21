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
            // Thumbnail with subtle shadow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: game.localThumbnail != null
                    ? Image.asset(
                        game.localThumbnail!,
                        width: width,
                        height: width,
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: game.thumbnailUrl,
                        width: width,
                        height: width,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: width,
                          height: width,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.gamepad,
                              size: 32, color: Colors.grey),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: width,
                          height: width,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.broken_image,
                              size: 32, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              game.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 14, color: Colors.amber[600]),
                const SizedBox(width: 3),
                Text(
                  game.rating.toStringAsFixed(1),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    game.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
