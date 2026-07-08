-- ============================================================
-- SEED BOARDS PINTEREST POUR COLLECTE D'IMAGES MANGA
-- À exécuter APRÈS le seed des styles manga (seed-all.sql)
--
-- ⚠️  ATTENTION : Les usernames Pinterest doivent être VALIDES.
-- Pinterest ne supporte plus les flux RSS, le collecteur scrape
-- le HTML des boards. Utilise des comptes réels.
--
-- Boards confirmés fonctionnels :
--   lightertower/bleach (1797 pins, fonctionnel ✓)
--   animeart/референсы (références dessin, fonctionnel ✓)
--
-- Remplace les usernames ci-dessous par de VRAIS comptes Pinterest
-- ayant des boards pour chaque style manga.
-- ============================================================

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'bleach', 'tite-kubo', 'https://www.pinterest.com/lightertower/bleach/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'tite-kubo');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'one-piece', 'eiichiro-oda', 'https://www.pinterest.com/lightertower/one-piece/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'eiichiro-oda');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'naruto', 'masashi-kishimoto', 'https://www.pinterest.com/lightertower/naruto/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'masashi-kishimoto');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'dragon-ball', 'akira-toriyama', 'https://www.pinterest.com/lightertower/dragon-ball/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'akira-toriyama');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'attack-on-titan', 'hajime-iseyama', 'https://www.pinterest.com/lightertower/attack-on-titan/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'hajime-iseyama');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'demon-slayer', 'koyoharu-gotouge', 'https://www.pinterest.com/lightertower/demon-slayer/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'koyoharu-gotouge');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'jujutsu-kaisen', 'gege-akutami', 'https://www.pinterest.com/lightertower/jujutsu-kaisen/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'gege-akutami');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'my-hero-academia', 'kohei-horikoshi', 'https://www.pinterest.com/lightertower/my-hero-academia/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'kohei-horikoshi');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'berserk', 'kentaro-miura', 'https://www.pinterest.com/lightertower/berserk/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'kentaro-miura');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'vagabond', 'takehiko-inoue', 'https://www.pinterest.com/lightertower/vagabond/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'takehiko-inoue');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'one-punch-man', 'yusuke-murata', 'https://www.pinterest.com/lightertower/one-punch-man/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'yusuke-murata');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'sailor-moon', 'naoko-takeuchi', 'https://www.pinterest.com/lightertower/sailor-moon/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'naoko-takeuchi');

INSERT INTO ai_pinterest_sources (username, board_name, style_slug, board_url, is_active)
SELECT 'lightertower', 'junji-ito', 'junji-ito', 'https://www.pinterest.com/lightertower/junji-ito/', true
WHERE EXISTS (SELECT 1 FROM ai_manga_styles WHERE slug = 'junji-ito');

SELECT '✅ ' || COUNT(*) || ' boards Pinterest ajoutés !' as result FROM ai_pinterest_sources;
