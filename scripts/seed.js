const admin = require("firebase-admin");

// Use application default credentials (firebase login already done)
const app = admin.initializeApp({ projectId: "centplay-demo" });
const db = admin.firestore();

async function seed() {
  // Games
  const games = [
    {
      id: "pizza-ready",
      title: "Pizza Ready",
      description: "전 세계에서 사랑받는 피자 타이쿤 게임",
      thumbnailUrl: "https://picsum.photos/seed/pizza/400/400",
      webglUrl: "https://nickytsui.itch.io/ball-bouncer",
      rank: 1,
      rating: 4.8,
      isRecommended: true,
      category: "casual",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: "burger-please",
      title: "Burger Please!",
      description: "최고의 버거를 만들어보세요",
      thumbnailUrl: "https://picsum.photos/seed/burger/400/400",
      webglUrl: "",
      rank: 2,
      rating: 4.7,
      isRecommended: true,
      category: "casual",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: "snake-clash",
      title: "Snake Clash",
      description: "뱀 배틀 로얄! 최후의 1마리가 되세요",
      thumbnailUrl: "https://picsum.photos/seed/snake/400/400",
      webglUrl: "",
      rank: 3,
      rating: 4.5,
      isRecommended: false,
      category: "action",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: "xp-hero",
      title: "XP Hero",
      description: "경험치를 모아 영웅이 되세요",
      thumbnailUrl: "https://picsum.photos/seed/hero/400/400",
      webglUrl: "",
      rank: 4,
      rating: 4.3,
      isRecommended: true,
      category: "idle",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      id: "centplay-demo",
      title: "CentPlay Demo",
      description: "CentPlay 데모 미니게임",
      thumbnailUrl: "https://picsum.photos/seed/demo/400/400",
      webglUrl: "",
      rank: 5,
      rating: 4.0,
      isRecommended: false,
      category: "demo",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  // Videos
  const videos = [
    {
      id: "video-1",
      title: "Pizza Ready 시즌2 예고편",
      videoUrl:
        "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
      thumbnailUrl: "https://picsum.photos/seed/vid1/800/450",
      viewCount: 123000,
    },
    {
      id: "video-2",
      title: "Burger Please 업데이트 소식",
      videoUrl:
        "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
      thumbnailUrl: "https://picsum.photos/seed/vid2/800/450",
      viewCount: 45000,
    },
  ];

  console.log("Seeding games...");
  for (const game of games) {
    const { id, ...data } = game;
    await db.collection("games").doc(id).set(data);
    console.log(`  ✓ ${game.title}`);
  }

  console.log("Seeding videos...");
  for (const video of videos) {
    const { id, ...data } = video;
    await db.collection("videos").doc(id).set(data);
    console.log(`  ✓ ${video.title}`);
  }

  console.log("\nDone! Seeded 5 games + 2 videos.");
  process.exit(0);
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
