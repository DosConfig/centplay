// Firestore에 MDC 게임 항목 추가 스크립트
// 사용법: node scripts/add_mdc_game.js

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Firebase Admin 초기화 (프로젝트 기본 인증 사용)
initializeApp({ projectId: 'centplay-demo' });
const db = getFirestore();

async function addMDC() {
  await db.collection('games').doc('mdc').set({
    title: 'Monster Dispatch Corps',
    description: 'Unity WebGL 기반 몬스터 파견 전략 게임. 몬스터를 수집하고 던전을 탐험하세요.',
    thumbnailUrl: '',
    webglUrl: 'https://centplay-demo.web.app/mdc/index.html',
    trailerUrl: '',
    rank: 1,
    rating: 0.0,
    isRecommended: true,
    category: 'strategy',
  });
  console.log('✅ MDC 게임 항목 추가 완료');
}

addMDC().catch(console.error);
