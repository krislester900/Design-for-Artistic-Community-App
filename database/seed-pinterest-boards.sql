-- ============================================================
-- SEED BOARDS PINTEREST POUR COLLECTE D'IMAGES MANGA
-- À exécuter APRÈS le seed des styles manga (seed-all.sql)
-- ============================================================

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'bleach-art', 'tite-kubo', 'https://www.pinterest.com/pinterest/bleach-art', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'tite-kubo');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'one-piece-art', 'eiichiro-oda', 'https://www.pinterest.com/pinterest/one-piece-art', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'eiichiro-oda');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'naruto-art', 'masashi-kishimoto', 'https://www.pinterest.com/pinterest/naruto-art', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'masashi-kishimoto');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'dragon-ball-art', 'akira-toriyama', 'https://www.pinterest.com/pinterest/dragon-ball-art', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'akira-toriyama');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'attack-on-titan', 'hajime-iseyama', 'https://www.pinterest.com/pinterest/attack-on-titan', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'hajime-iseyama');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'demon-slayer', 'koyoharu-gotouge', 'https://www.pinterest.com/pinterest/demon-slayer', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'koyoharu-gotouge');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'jujutsu-kaisen', 'gege-akutami', 'https://www.pinterest.com/pinterest/jujutsu-kaisen', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'gege-akutami');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'my-hero-academia', 'kohei-horikoshi', 'https://www.pinterest.com/pinterest/my-hero-academia', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'kohei-horikoshi');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'berserk-art', 'kentaro-miura', 'https://www.pinterest.com/pinterest/berserk-art', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'kentaro-miura');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'vagabond-manga', 'takehiko-inoue', 'https://www.pinterest.com/pinterest/vagabond-manga', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'takehiko-inoue');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'one-punch-man', 'yusuke-murata', 'https://www.pinterest.com/pinterest/one-punch-man', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'yusuke-murata');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'sailor-moon', 'naoko-takeuchi', 'https://www.pinterest.com/pinterest/sailor-moon', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'naoko-takeuchi');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'pinterest', 'junji-ito', 'junji-ito', 'https://www.pinterest.com/pinterest/junji-ito', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'junji-ito');

SELECT '✅ ' || COUNT(*) || ' boards Pinterest ajoutés !' as result FROM ai_pinterest_sources;
