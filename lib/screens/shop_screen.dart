import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ShopItem(
          name: '코인 100개',
          price: '₩1,200',
          icon: Icons.monetization_on,
          color: Colors.amber),
      _ShopItem(
          name: '코인 500개',
          price: '₩4,900',
          icon: Icons.monetization_on,
          color: Colors.orange),
      _ShopItem(
          name: '코인 1,200개',
          price: '₩9,900',
          icon: Icons.monetization_on,
          color: Colors.deepOrange),
      _ShopItem(
          name: 'VIP 패스 (30일)',
          price: '₩12,000',
          icon: Icons.workspace_premium,
          color: Colors.purple),
      _ShopItem(
          name: '광고 제거',
          price: '₩5,900',
          icon: Icons.block,
          color: Colors.teal),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('상점')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.color.withValues(alpha: 0.15),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('데모 버전에서는 결제가 지원되지 않습니다')),
                  );
                },
                child: Text(item.price),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShopItem {
  final String name;
  final String price;
  final IconData icon;
  final Color color;

  const _ShopItem(
      {required this.name,
      required this.price,
      required this.icon,
      required this.color});
}
