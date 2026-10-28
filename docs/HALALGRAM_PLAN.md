# HALALGRAM_PLAN.md — Execution Plan v1

## ملخص للمالك (Arabic summary)

- هذا الملف هو الخطة التنفيذية الوحيدة لتحويل مشروع `instagram` إلى تطبيق **حلال كرام (Halalgram)**: تطبيق تواصل اجتماعي بهوية إسلامية يحاكي تخطيط إنستغرام الحديث دون نسخ شعاره أو ألوانه.
- الواجهة عربية أولاً (RTL) مع الإنجليزية، ثيم فاتح وداكن، لون أخضر داكن مع ذهبي هادئ، وخط Cairo مضمّن داخل التطبيق.
- الخلفية Supabase فقط (مشروع سحابي)، ويُزال Firebase بالكامل في المرحلة 9.
- البنية: Clean Architecture مقسّمة حسب الميزات، Riverpod 3 مع التوليد، go_router، freezed، fpdart.
- الخطة مقسّمة إلى 10 مراحل (0–9) و111 مهمة صغيرة، كل مهمة لها ملفات محددة وخطوات وأوامر تحقق وCommit مستقل.
- برومبت جلسة المنفّذ جاهز في `docs/EXECUTOR_PROMPT.md`. الصقه كما هو في جلسة جديدة.
- المهام المعلّمة `OWNER-ACTION` تحتاج تدخّلك أنت (إنشاء مشروع Supabase، كلمات السر، التوقيع للنشر).
- المنفّذ (وكيل ذكاء اصطناعي) ملزم بـ"عقد المنفّذ" أدناه: لا ارتجال، لا حزم جديدة، يتوقف ويسأل عند أي غموض.
- تابع التقدّم من جدول "Progress log" في آخر الملف.

---

## 0. How to use this file (executor quick start)

1. Read §1 EXECUTOR CONTRACT fully once per session. The session prompt is `docs/EXECUTOR_PROMPT.md`; if it conflicts with this file, this file wins.
2. Find the first unchecked task in §7. Do ONLY that task, then continue to the next until an `OWNER-ACTION` or a STOP rule.
3. For that task, read only: its task block, the §2/§3/§4/§6 subsections it references, and the files it lists.
4. Run the task's verification block. Fix until green.
5. Tick the checkbox `[x]`, add a row to §10 Progress log, commit with the exact commit message given.
6. Go to the next task. At a phase end, run that phase's Definition of Done (§8).

Shorthands used in tasks:
- `ROOT` = `/Users/abo_alhuda/Documents/flutter_projects_abo_alhuda/Social Media/instagram` (all paths relative to ROOT; always `cd` there first; quote the path, it contains a space).
- `VERIFY-STD` = the standard verification block in §1.3.
- `OWNER-ACTION` = STOP, print the exact request to the owner, wait. Never fake it.

---

## 1. EXECUTOR CONTRACT

### 1.1 MUST
1. MUST work on exactly one task ID at a time, in the order listed in §7. Dependencies listed in a task MUST be checked `[x]` first.
2. MUST read only the files listed in the task (plus this plan). Do not explore the repo "for context".
3. MUST create/modify/delete exactly the files listed in the task. If an extra file seems necessary → STOP and report.
4. MUST use `fvm flutter ...` and `fvm dart ...` for every Flutter/Dart command. Never plain `flutter`/`dart`.
5. MUST run `VERIFY-STD` (§1.3) after every task that touches Dart/pubspec/assets. `fvm flutter analyze` MUST print `No issues found!`. `bash tool/check_rules.sh` MUST print `OK`.
6. MUST run `fvm flutter test` when the task creates/changes tests or `test/` is non-empty; all tests MUST pass.
7. MUST make one commit per task with the exact message from the task (format `<type>(<scope>): <TASK-ID> <summary>`). Stage only files of this task (`git add <paths>`; `git add -A` is allowed only when the task says so).
8. MUST tick the task checkbox in §7 and append one row to §10 Progress log (date, task id, status, ≤15-word note) before committing; include this plan file in the commit.
9. MUST localize every user-visible string through `easy_localization` keys (`LocaleKeys.x.tr()`), adding the key to BOTH `assets/translations/ar.json` and `assets/translations/en.json` in the same task.
10. MUST use design tokens (§4) for every color, spacing, radius, size, font size, duration. Only exception: `Colors.transparent`.
11. MUST use directional APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `start/end`) — never `left/right` for layout.
12. MUST follow the code templates in §3.4 exactly (naming, file location, generator syntax).
13. MUST write SQL migrations exactly to the spec in §6 (names, columns, types, constraints, policies, signatures). New migration file names are fixed in the task.
14. MUST push migrations with `supabase db push` only in the task that creates them, and verify with `supabase migration list` (remote column filled).
15. MUST keep edits minimal: use targeted edits, not full-file rewrites, when a file already exists and the change is small.
16. MUST prefer `const` constructors, `final` fields, and `super.key`.
17. MUST STOP and report (task ID, what blocked, exact error, what you tried once) when: a command fails twice; an API in this plan does not match the installed package; a spec is ambiguous; a needed package/file is not listed; an `OWNER-ACTION` is reached.
18. MUST, before writing SQL, copy names from the cited §6 table into the file. A function, column, policy, or trigger not named in §6 is forbidden. A function named in the task's object list and missing from the file means the task is not done.
19. MUST run the task's **Verify** line. For Phase 2 that line is `DB-STD` (the five steps under the Phase 2 heading). "Accept: DB-STD green" is not a substitute for running those commands.

### 1.2 MUST NOT
1. MUST NOT add, remove, or upgrade any package not in §5 (approved list). Need something else → STOP and ask.
2. MUST NOT change theme tokens, router structure, DB schema, or `pubspec.yaml` outside a task that explicitly lists them.
3. MUST NOT import `package:supabase_flutter` anywhere except: `lib/bootstrap.dart`, `lib/core/network/**`, `lib/core/di/**`, `lib/features/*/data/**`, `lib/features/*/di/**`.
4. MUST NOT import `lib/features/<x>/data/**` from any `presentation/` or `domain/` folder. Presentation reaches data ONLY via `lib/features/<x>/di/` providers.
5. MUST NOT import `package:flutter/...` in any `domain/` folder.
6. MUST NOT hardcode strings, colors, sizes, or durations in widgets.
7. MUST NOT use `print`/`debugPrint`; use the `logger` provider (`ref.read(loggerProvider)`).
8. MUST NOT edit migrations `001`–`003` (single exception defined in P0-T09). Never edit an already-pushed migration; fixes go into the next numbered file and require an owner-approved new task.
9. MUST NOT use or store the Supabase `service_role` key, DB password, or any secret in the repo or app. `env/*.json` is gitignored except `env/example.json` and `env/ci.json` (fake CI values only). Never commit or print `env/dev.json` or `env/prod.json`.
10. MUST NOT delete files that are not listed in a task.
11. MUST NOT copy code from external repositories unless their LICENSE is MIT/BSD/Apache-2.0 and the task allows it; record source URL in the commit body.
12. MUST NOT re-read unchanged files, paste large files into reasoning, or write long explanations. Report results in ≤10 lines.
13. MUST NOT "improve" unrelated code, rename things, reformat untouched files (only `fvm dart format` on files you touched or as VERIFY-STD does), or leave TODOs without an issue note in §10.
14. MUST NOT copy Instagram's logo, wordmark, gradients, or official icon assets.
15. MUST NOT add music/audio-track features anywhere.

### 1.3 VERIFY-STD (run from ROOT)
```bash
cd "/Users/abo_alhuda/Documents/flutter_projects_abo_alhuda/Social Media/instagram"
fvm flutter pub get
fvm dart run easy_localization:generate -S assets/translations -O lib/core/l10n -o locale_keys.g.dart -f keys   # only after P1-T08
fvm dart run build_runner build -d
fvm dart format lib test
fvm flutter analyze            # must print: No issues found!
bash tool/check_rules.sh       # must print: OK      (after P0-T08)
fvm flutter test               # when test/ contains tests
```
Phase-end build check (Android, debug): `fvm flutter build apk --debug --dart-define-from-file=env/dev.json`
Phase-end build check (iOS, no signing): `fvm flutter build ios --debug --no-codesign --dart-define-from-file=env/dev.json`
If a build fails only because no JDK/Xcode is available in the shell → record in §10 and ask the owner to run it (OWNER-ACTION); do not change Gradle/Xcode settings to work around it.

### 1.4 Supabase CLI notes
- Run Supabase CLI from ROOT. It writes to `~/.supabase`; if a sandbox blocks it, rerun with full permissions.
- Never run `supabase db reset` (no Docker/local DB). Never run `supabase db push --include-all` unless the task says so.
- Remote SQL checks: owner runs SQL in Dashboard → SQL Editor, OR the executor uses the Supabase MCP `execute_sql` tool if available and the owner approved it in §10.

---

## 2. Product spec (frozen)

| Item | Decision |
|---|---|
| App name | EN `Halalgram`, AR `حلال كرام` |
| Dart package name | `halalgram` |
| Android applicationId / namespace | `com.halalgram.app` |
| iOS bundle id | `com.halalgram.app` (tests: `com.halalgram.app.RunnerTests`) |
| Platforms | Android + iOS only (web/linux/macos/windows folders deleted in P9) |
| Default locale | `ar` (RTL); also `en`. Fallback `ar`. |
| Theme | light + dark + system; default system |
| Font | Cairo, bundled TTF assets (weights 400/600/700/800) |
| Backend | Supabase cloud only: Auth (email+password, email OTP codes), Postgres, Storage, Realtime |
| Config | `--dart-define-from-file=env/dev.json` with keys `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` |
| Navigation | Bottom nav: Home, Explore, Create(+), Reels, Profile. Home app bar: wordmark (start), Notifications heart + Messages icon (end) |
| Content rules | No music in reels (original audio or muted); report + block; guidelines notice in create flows; moderation tables with RLS |
| Islamic touches | Hijri + Gregorian date in post detail and occasion banner; occasion banners (Ramadan, Eid al-Fitr, Eid al-Adha, Jumu'ah) on Home; modest polite copy |
| Out of scope v1 | Live, shop, ads, multi-account, AI, push notifications (FCM), story stickers/text, video in carousels, reel comment replies, typing indicators, message requests, group chats, music |

### 2.1 Copy tone + glossary (use these exact Arabic terms)
Tone: polite, short, gender-neutral where possible, no slang, no exclamation spam. Errors apologize briefly ("عذرًا، ...").

| EN | AR |
|---|---|
| Home | الرئيسية |
| Explore | استكشاف |
| Search | بحث |
| Create | إنشاء |
| Reels | المقاطع |
| Reel | مقطع |
| Profile | الملف الشخصي |
| Post | منشور |
| Story / Stories | قصة / القصص |
| Your story | قصتك |
| Highlights | أبرز القصص |
| Like | إعجاب |
| Comment / Comments | تعليق / التعليقات |
| Reply | رد |
| Share | مشاركة |
| Save / Saved | حفظ / المحفوظات |
| Follow | متابعة |
| Following (button) | تتابعه |
| Follow back | متابعة بالمثل |
| Requested | تم الطلب |
| Followers | المتابِعون |
| Following (count) | يتابع |
| Messages | الرسائل |
| Notifications | الإشعارات |
| Edit profile | تعديل الملف |
| Private account | حساب خاص |
| Block / Unblock | حظر / إلغاء الحظر |
| Report | إبلاغ |
| Settings | الإعدادات |
| Log out | تسجيل الخروج |
| Original audio | الصوت الأصلي |
| Muted | بدون صوت |
| Content guidelines | إرشادات المحتوى |
| Jumu'ah Mubarak | جمعة مباركة |
| Ramadan Kareem | رمضان كريم |
| Eid Mubarak | عيد مبارك |
| AH (Hijri suffix) | هـ |

### 2.2 Content guidelines text (use verbatim; keys `guidelines.item_1..7`)
| # | AR | EN |
|---|---|---|
| 1 | انشر محتوى محترمًا ولائقًا يليق بالجميع. | Share respectful, modest content suitable for everyone. |
| 2 | يُمنع المحتوى العاري أو الخادش للحياء. | No nudity or indecent content. |
| 3 | لا موسيقى في المقاطع؛ استخدم الصوت الأصلي أو اكتم الصوت. | No music in reels; use original audio or mute. |
| 4 | يُمنع خطاب الكراهية والسخرية من الأديان والمضايقة. | No hate speech, mocking of religions, or harassment. |
| 5 | يُمنع الترويج للعنف أو القمار أو الخمور أو المخدرات. | No promotion of violence, gambling, alcohol, or drugs. |
| 6 | احترم الخصوصية ولا تنشر صور الآخرين دون إذنهم. | Respect privacy; don't post others' photos without permission. |
| 7 | أبلغ عن أي محتوى يخالف هذه الإرشادات. | Report any content that breaks these guidelines. |

---

## 3. Architecture spec

### 3.1 Final folder tree (target at end of P9)
```
instagram/                      (ROOT)
├─ AGENTS.md
├─ .cursor/rules/halalgram-core.mdc, halalgram-features.mdc, halalgram-migrations.mdc
├─ analysis_options.yaml, build.yaml, pubspec.yaml, flutter_native_splash.yaml, flutter_launcher_icons.yaml
├─ env/example.json             (committed)   env/dev.json (gitignored, owner-filled)
├─ tool/check_rules.sh
├─ assets/
│  ├─ brand/logo_mark.svg, app_icon_1024.png, splash_logo.png
│  ├─ fonts/Cairo-Regular.ttf, Cairo-SemiBold.ttf, Cairo-Bold.ttf, Cairo-ExtraBold.ttf
│  └─ translations/ar.json, en.json
├─ docs/HALALGRAM_PLAN.md
├─ supabase/config.toml, migrations/001…017_*.sql, tests/rls_smoke.sql
├─ lib/
│  ├─ main.dart                 (calls bootstrap)
│  ├─ bootstrap.dart            (init order, runApp)
│  ├─ app.dart                  (HalalgramApp: MaterialApp.router)
│  ├─ core/
│  │  ├─ config/app_env.dart
│  │  ├─ constants/app_constants.dart, storage_buckets.dart, media_limits.dart, prefs_keys.dart
│  │  ├─ di/core_providers.dart                 (supabaseClient, sharedPreferences, logger, storageService)
│  │  ├─ errors/failure.dart, result.dart, failure_message.dart
│  │  ├─ l10n/locale_keys.g.dart (generated), l10n_setup.dart
│  │  ├─ network/auth_session.dart, error_mapper.dart, guard.dart, storage_service.dart
│  │  ├─ pagination/cursor.dart, page_result.dart, cursor_paging_controller.dart
│  │  ├─ media/media_picker.dart, image_compressor.dart, video_controller_pool.dart
│  │  ├─ router/app_routes.dart, app_router.dart
│  │  ├─ shell/main_shell.dart, halal_bottom_nav.dart, create_sheet.dart
│  │  ├─ theme/app_colors.dart, app_spacing.dart, app_radii.dart, app_sizes.dart, app_durations.dart,
│  │  │        app_typography.dart, halal_colors.dart, app_theme.dart, theme_mode_controller.dart
│  │  ├─ utils/validators.dart, formatters.dart, hijri_date.dart, occasions.dart, debouncer.dart, context_ext.dart
│  │  └─ widgets/ (see §4.6 list)
│  └─ features/
│     ├─ auth/  profile/  feed/  post/  comments/  story/  reel/
│     ├─ explore/  follow/  chat/  notifications/  moderation/  settings/
│     └─ <feature>/
│        ├─ data/{datasources,models,repositories}/
│        ├─ domain/{entities,repositories,usecases}/
│        ├─ di/<feature>_providers.dart
│        └─ presentation/{providers,screens,widgets}/
└─ test/ (mirrors lib/: test/core/**, test/features/<feature>/**, test/helpers/pump_app.dart)
```
Note: `di/` per feature is the composition root (only place wiring data → domain). This is the single allowed deviation from a pure 3-folder slice.

### 3.2 Layer rules
| Layer | May import | Must not import |
|---|---|---|
| `domain/` | `fpdart`, `freezed_annotation`, `core/errors/*`, `core/pagination/cursor.dart`, `core/pagination/page_result.dart`, other features' `domain/**` | flutter, supabase, data, presentation, di |
| `data/` | own `domain/`, other features' `domain/**`, `core/network/**`, `core/constants/**`, `core/errors/**`, `core/pagination/**`, `core/media/image_compressor.dart`, supabase, json/freezed | presentation, di, other features' `data/` |
| `di/` | own `data/` + `domain/`, `core/di/**`, riverpod | presentation |
| `presentation/` | own `domain/` + `di/`, other features' `domain/**`, `di/**`, `presentation/widgets/**`; `core/**` except `core/network/error_mapper.dart`, `guard.dart`, `storage_service.dart` | supabase, any `data/` |
| `core/widgets`, `core/theme`, `core/router`, `core/shell`, `core/utils` | flutter, approved UI packages, `core/**` (router may import feature screens and `core/network/auth_session.dart`) | supabase |

Cross-feature UI reuse (e.g. `PostCard` used by feed/explore/profile) is via `features/post/presentation/widgets/`.

### 3.3 Naming conventions
| Thing | Rule | Example |
|---|---|---|
| Files | `snake_case.dart` | `post_repository_impl.dart` |
| Entity | Noun, no suffix, in `domain/entities/` | `Post`, `UserSummary` |
| Model | `<Name>Model`, in `data/models/` | `FeedPostModel` |
| Datasource | `<Feature>RemoteDataSource` (concrete class) | `PostRemoteDataSource` |
| Repo interface | `<Feature>Repository` (`abstract interface class`) | `PostRepository` |
| Repo impl | `<Feature>RepositoryImpl` | `PostRepositoryImpl` |
| Use case | VerbNoun class with `call(...)` | `LikePost`, `GetHomeFeed` |
| DI provider fn | lowerCamel of the class; generated name ends `Provider` | `likePost` → `likePostProvider` |
| Notifier | `<Thing>Controller` | `ProfileController` → `profileControllerProvider` |
| Screen | `<Name>Screen` in `presentation/screens/<name>_screen.dart` | `HomeScreen` |
| Widget | descriptive noun | `PostCard`, `StoriesBar` |
| Route constant | `AppRoutes.<name>` path + `AppRoutes.<name>Name` | `AppRoutes.postDetail` |
| l10n key | `<feature>.<screen_or_widget>.<name>` snake_case | `auth.login.title` → `LocaleKeys.auth_login_title` |
| SQL | snake_case; tables plural; RPC verbs; params prefixed `p_` | `get_home_feed(p_limit ...)` |
| Storage path | `{user_id}/...` first segment always the owner uid | see §6.5 |

### 3.4 Code templates (copy structure exactly; these compile with the §5 versions)

`build.yaml` (ROOT, created in P1-T01):
```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          field_rename: snake
          explicit_to_json: true
          checked: false
```

**T1 Failure + Result** — `lib/core/errors/failure.dart`, `lib/core/errors/result.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure implements Exception {
  const factory Failure.network() = NetworkFailure;
  const factory Failure.unauthorized() = UnauthorizedFailure;
  const factory Failure.invalidCredentials() = InvalidCredentialsFailure;
  const factory Failure.emailNotConfirmed() = EmailNotConfirmedFailure;
  const factory Failure.emailInUse() = EmailInUseFailure;
  const factory Failure.usernameTaken() = UsernameTakenFailure;
  const factory Failure.weakPassword() = WeakPasswordFailure;
  const factory Failure.invalidOtp() = InvalidOtpFailure;
  const factory Failure.rateLimited() = RateLimitedFailure;
  const factory Failure.notFound() = NotFoundFailure;
  const factory Failure.permissionDenied() = PermissionDeniedFailure;
  const factory Failure.conflict() = ConflictFailure;
  const factory Failure.validation({required String messageKey}) =
      ValidationFailure;
  const factory Failure.storage() = StorageFailure;
  const factory Failure.server({required String code, String? message}) =
      ServerFailure;
  const factory Failure.unknown({Object? error}) = UnknownFailure;
}
```
```dart
// result.dart
import 'package:fpdart/fpdart.dart';
import 'package:halalgram/core/errors/failure.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;
```

**T2 Error mapping + guard** — `lib/core/network/error_mapper.dart`, `lib/core/network/guard.dart`
```dart
// error_mapper.dart
import 'dart:async';
import 'dart:io';

import 'package:halalgram/core/errors/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Failure mapError(Object error) {
  if (error is Failure) return error;
  if (error is SocketException || error is TimeoutException) {
    return const Failure.network();
  }
  if (error is AuthRetryableFetchException) return const Failure.network();
  if (error is AuthException) return _mapAuth(error);
  if (error is PostgrestException) return _mapPostgrest(error);
  if (error is StorageException) return const Failure.storage();
  return Failure.unknown(error: error);
}

Failure _mapAuth(AuthException e) => switch (e.code) {
      'invalid_credentials' => const Failure.invalidCredentials(),
      'email_not_confirmed' => const Failure.emailNotConfirmed(),
      'user_already_exists' || 'email_exists' => const Failure.emailInUse(),
      'weak_password' => const Failure.weakPassword(),
      'otp_expired' || 'otp_disabled' => const Failure.invalidOtp(),
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        const Failure.rateLimited(),
      _ when e.statusCode == '401' => const Failure.unauthorized(),
      _ => Failure.server(code: e.code ?? 'auth', message: e.message),
    };

Failure _mapPostgrest(PostgrestException e) => switch (e.code) {
      '23505' when e.message.contains('username') =>
        const Failure.usernameTaken(),
      '23505' => const Failure.conflict(),
      '42501' => const Failure.permissionDenied(),
      'PGRST116' => const Failure.notFound(),
      '23514' || '22001' =>
        const Failure.validation(messageKey: 'errors.invalid_input'),
      'P0001' when e.message == 'blocked' => const Failure.permissionDenied(),
      'P0001' when e.message == 'not_found' => const Failure.notFound(),
      _ => Failure.server(code: e.code ?? 'db', message: e.message),
    };
```
```dart
// guard.dart
import 'package:fpdart/fpdart.dart';
import 'package:halalgram/core/errors/result.dart';
import 'package:halalgram/core/network/error_mapper.dart';

FutureEither<T> guard<T>(Future<T> Function() body) async {
  try {
    return right(await body());
  } on Object catch (error) {
    return left(mapError(error));
  }
}
```
Custom RPC errors: SQL raises `RAISE EXCEPTION 'blocked'` / `'not_found'` / `'private'` (SQLSTATE P0001). Add new codes only via spec.

**T3 Failure → message** — `lib/core/errors/failure_message.dart`: `extension FailureMessage on Failure { String get messageKey => switch (this) { NetworkFailure() => LocaleKeys.errors_network, ... ValidationFailure(:final messageKey) => messageKey, ... }; }` and top-level `String failureMessageKey(Object error) => error is Failure ? error.messageKey : LocaleKeys.errors_unknown;` (one case per Failure variant, keys listed in P1-T08).

**T4 Pagination** — `lib/core/pagination/cursor.dart`, `page_result.dart`, `cursor_paging_controller.dart`
```dart
// cursor.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cursor.freezed.dart';

@freezed
abstract class Cursor with _$Cursor {
  const factory Cursor({required DateTime createdAt, required String id}) =
      _Cursor;
}
```
```dart
// page_result.dart
import 'package:halalgram/core/pagination/cursor.dart';

class PageResult<T> {
  const PageResult({required this.items, required this.nextCursor});

  factory PageResult.fromItems(
    List<T> items, {
    required int pageSize,
    required Cursor Function(T item) cursorOf,
  }) =>
      PageResult(
        items: items,
        nextCursor: items.length < pageSize ? null : cursorOf(items.last),
      );

  final List<T> items;
  final Cursor? nextCursor;

  bool get hasMore => nextCursor != null;
}
```
```dart
// cursor_paging_controller.dart
import 'package:halalgram/core/errors/result.dart';
import 'package:halalgram/core/pagination/cursor.dart';
import 'package:halalgram/core/pagination/page_result.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// Page keys are 1,2,3…; the real cursor is kept in the closure.
PagingController<int, T> cursorPagingController<T>({
  required FutureEither<PageResult<T>> Function(Cursor? before) fetch,
}) {
  Cursor? next;
  var hasMore = true;
  return PagingController<int, T>(
    getNextPageKey: (state) {
      final keys = state.keys;
      if (keys == null || keys.isEmpty) {
        next = null;
        hasMore = true;
        return 1;
      }
      return hasMore ? keys.last + 1 : null;
    },
    fetchPage: (pageKey) async {
      final result = await fetch(pageKey == 1 ? null : next);
      return result.match((failure) => throw failure, (page) {
        next = page.nextCursor;
        hasMore = page.hasMore;
        return page.items;
      });
    },
  );
}
```

**T5 Entity** — `lib/features/post/domain/entities/post.dart` (required named params FIRST, `@Default` last)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:halalgram/features/post/domain/entities/post_media.dart';
import 'package:halalgram/features/profile/domain/entities/user_summary.dart';

part 'post.freezed.dart';

@freezed
abstract class Post with _$Post {
  const factory Post({
    required String id,
    required UserSummary author,
    required List<PostMedia> media,
    required double aspectRatio,
    required int likesCount,
    required int commentsCount,
    required bool isLiked,
    required bool isSaved,
    required DateTime createdAt,
    @Default('') String caption,
    @Default('') String location,
  }) = _Post;
}
```

**T6 Model** — `lib/features/post/data/models/feed_post_model.dart` (snake_case JSON via build.yaml; no `@JsonKey` unless name differs from snake of field)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:halalgram/core/constants/storage_buckets.dart';
import 'package:halalgram/core/network/storage_service.dart';
import 'package:halalgram/features/post/data/models/post_media_model.dart';
import 'package:halalgram/features/post/domain/entities/post.dart';
import 'package:halalgram/features/profile/domain/entities/user_summary.dart';

part 'feed_post_model.freezed.dart';
part 'feed_post_model.g.dart';

@freezed
abstract class FeedPostModel with _$FeedPostModel {
  const factory FeedPostModel({
    required String postId,
    required String authorId,
    required String authorUsername,
    required double aspectRatio,
    required int likesCount,
    required int commentsCount,
    required bool isLiked,
    required bool isSaved,
    required DateTime createdAt,
    required List<PostMediaModel> media,
    String? authorFullName,
    String? authorAvatarPath,
    String? caption,
    String? location,
  }) = _FeedPostModel;

  const FeedPostModel._();

  factory FeedPostModel.fromJson(Map<String, dynamic> json) =>
      _$FeedPostModelFromJson(json);

  Post toEntity(StorageService storage) => Post(
        id: postId,
        author: UserSummary(
          id: authorId,
          username: authorUsername,
          fullName: authorFullName ?? '',
          avatarUrl: storage.publicUrlOrNull(
            StorageBuckets.avatars,
            authorAvatarPath,
          ),
        ),
        media: media.map((m) => m.toEntity(storage)).toList(),
        aspectRatio: aspectRatio,
        likesCount: likesCount,
        commentsCount: commentsCount,
        isLiked: isLiked,
        isSaved: isSaved,
        createdAt: createdAt,
        caption: caption ?? '',
        location: location ?? '',
      );
}
```

**T7 Datasource** — `lib/features/post/data/datasources/post_remote_data_source.dart` (throws raw exceptions; no Either here)
```dart
import 'package:halalgram/core/pagination/cursor.dart';
import 'package:halalgram/features/post/data/models/feed_post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRemoteDataSource {
  const PostRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<FeedPostModel>> getHomeFeed({
    required int limit,
    Cursor? before,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_home_feed',
      params: {
        'p_limit': limit,
        'p_before_created_at': before?.createdAt.toUtc().toIso8601String(),
        'p_before_id': before?.id,
      },
    );
    return rows
        .map((row) => FeedPostModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> likePost(String postId) => _client
      .from('post_likes')
      .insert({'post_id': postId, 'user_id': _client.auth.currentUser!.id});
}
```

**T8 Repository interface + impl**
```dart
// domain/repositories/post_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:halalgram/core/errors/result.dart';
import 'package:halalgram/core/pagination/cursor.dart';
import 'package:halalgram/core/pagination/page_result.dart';
import 'package:halalgram/features/post/domain/entities/post.dart';

abstract interface class PostRepository {
  FutureEither<PageResult<Post>> getHomeFeed({Cursor? before});
  FutureEither<Unit> likePost(String postId);
}
```
```dart
// data/repositories/post_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:halalgram/core/constants/app_constants.dart';
import 'package:halalgram/core/errors/result.dart';
import 'package:halalgram/core/network/guard.dart';
import 'package:halalgram/core/network/storage_service.dart';
import 'package:halalgram/core/pagination/cursor.dart';
import 'package:halalgram/core/pagination/page_result.dart';
import 'package:halalgram/features/post/data/datasources/post_remote_data_source.dart';
import 'package:halalgram/features/post/domain/entities/post.dart';
import 'package:halalgram/features/post/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl(this._remote, this._storage);

  final PostRemoteDataSource _remote;
  final StorageService _storage;

  @override
  FutureEither<PageResult<Post>> getHomeFeed({Cursor? before}) =>
      guard(() async {
        final models = await _remote.getHomeFeed(
          limit: AppConstants.feedPageSize,
          before: before,
        );
        return PageResult.fromItems(
          models.map((m) => m.toEntity(_storage)).toList(),
          pageSize: AppConstants.feedPageSize,
          cursorOf: (post) => Cursor(createdAt: post.createdAt, id: post.id),
        );
      });

  @override
  FutureEither<Unit> likePost(String postId) => guard(() async {
        await _remote.likePost(postId);
        return unit;
      });
}
```

**T9 Use case** — `domain/usecases/get_home_feed.dart`
```dart
import 'package:halalgram/core/errors/result.dart';
import 'package:halalgram/core/pagination/cursor.dart';
import 'package:halalgram/core/pagination/page_result.dart';
import 'package:halalgram/features/post/domain/entities/post.dart';
import 'package:halalgram/features/post/domain/repositories/post_repository.dart';

class GetHomeFeed {
  const GetHomeFeed(this._repository);

  final PostRepository _repository;

  FutureEither<PageResult<Post>> call({Cursor? before}) =>
      _repository.getHomeFeed(before: before);
}
```
Rule: every presentation → domain call goes through a use case (one class per action). Validation that needs no I/O lives in the use case and returns `left(Failure.validation(messageKey: ...))`.

**T10 DI providers** — `lib/features/post/di/post_providers.dart` (all DI providers `keepAlive: true`)
```dart
import 'package:halalgram/core/di/core_providers.dart';
import 'package:halalgram/features/post/data/datasources/post_remote_data_source.dart';
import 'package:halalgram/features/post/data/repositories/post_repository_impl.dart';
import 'package:halalgram/features/post/domain/repositories/post_repository.dart';
import 'package:halalgram/features/post/domain/usecases/get_home_feed.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_providers.g.dart';

@Riverpod(keepAlive: true)
PostRemoteDataSource postRemoteDataSource(Ref ref) =>
    PostRemoteDataSource(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) => PostRepositoryImpl(
      ref.watch(postRemoteDataSourceProvider),
      ref.watch(storageServiceProvider),
    );

@Riverpod(keepAlive: true)
GetHomeFeed getHomeFeed(Ref ref) => GetHomeFeed(ref.watch(postRepositoryProvider));
```

**T11 AsyncNotifier (read + mutation)** — `presentation/providers/profile_controller.dart`
```dart
import 'package:halalgram/core/errors/failure.dart';
import 'package:halalgram/features/profile/di/profile_providers.dart';
import 'package:halalgram/features/profile/domain/entities/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<Profile> build(String userId) async {
    final result = await ref.watch(getProfileProvider).call(userId);
    return result.getOrElse((failure) => throw failure);
  }

  /// Returns null on success, the Failure otherwise (UI shows snackbar).
  Future<Failure?> setPrivate({required bool isPrivate}) async {
    final result =
        await ref.read(setAccountPrivacyProvider).call(isPrivate: isPrivate);
    if (!ref.mounted) return null;
    return result.match((failure) => failure, (_) {
      ref.invalidateSelf();
      return null;
    });
  }
}
```

**T12 Optimistic family notifier** — `features/post/presentation/providers/post_interaction_controller.dart`
```dart
@riverpod
class PostInteractionController extends _$PostInteractionController {
  @override
  PostInteraction build(Post post) => PostInteraction(
        isLiked: post.isLiked,
        likesCount: post.likesCount,
        isSaved: post.isSaved,
      );

  Future<void> toggleLike() async {
    final before = state;
    state = before.copyWith(
      isLiked: !before.isLiked,
      likesCount: before.likesCount + (before.isLiked ? -1 : 1),
    );
    final result = before.isLiked
        ? await ref.read(unlikePostProvider).call(post.id)
        : await ref.read(likePostProvider).call(post.id);
    if (!ref.mounted) return;
    result.match((_) => state = before, (_) {});
  }
}
```
(`PostInteraction` is a freezed class in `features/post/domain/entities/post_interaction.dart` with `isLiked`, `likesCount`, `isSaved`.)

**T13 Screen (async)** — `presentation/screens/profile_screen.dart`
```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider(userId));
    return Scaffold(
      body: profile.when(
        data: (value) => ProfileView(profile: value),
        loading: () => const ProfileSkeleton(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(profileControllerProvider(userId)),
        ),
      ),
    );
  }
}
```

**T14 Paginated list screen**
```dart
class HomeFeedList extends ConsumerStatefulWidget {
  const HomeFeedList({super.key});

  @override
  ConsumerState<HomeFeedList> createState() => _HomeFeedListState();
}

class _HomeFeedListState extends ConsumerState<HomeFeedList> {
  late final PagingController<int, Post> _paging = cursorPagingController(
    fetch: (before) => ref.read(getHomeFeedProvider).call(before: before),
  );

  @override
  void dispose() {
    _paging.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _paging.refresh(),
      child: PagingListener(
        controller: _paging,
        builder: (context, state, fetchNextPage) => PagedListView<int, Post>(
          state: state,
          fetchNextPage: fetchNextPage,
          builderDelegate: PagedChildBuilderDelegate(
            itemBuilder: (context, post, index) => PostCard(post: post),
            firstPageProgressIndicatorBuilder: (_) => const PostCardSkeleton(),
            firstPageErrorIndicatorBuilder: (_) => ErrorView(
              error: state.error ?? const Failure.unknown(),
              onRetry: _paging.refresh,
            ),
            noItemsFoundIndicatorBuilder: (_) => EmptyView(
              icon: LucideIcons.image,
              messageKey: LocaleKeys.feed_home_empty,
            ),
          ),
        ),
      ),
    );
  }
}
```

**T15 Realtime stream (data layer)**
```dart
Stream<MessageModel> watchNewMessages(String conversationId) {
  late final RealtimeChannel channel;
  final controller = StreamController<MessageModel>(
    onCancel: () => _client.removeChannel(channel),
  );
  channel = _client
      .channel('messages:$conversationId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) =>
            controller.add(MessageModel.fromRealtime(payload.newRecord)),
      )
      .subscribe();
  return controller.stream;
}
```

**T16 Unit test (use case with mocktail)**
```dart
class _MockPostRepository extends Mock implements PostRepository {}

void main() {
  late _MockPostRepository repository;
  late LikePost likePost;

  setUp(() {
    repository = _MockPostRepository();
    likePost = LikePost(repository);
  });

  test('delegates to repository', () async {
    when(() => repository.likePost('p1')).thenAnswer((_) async => right(unit));
    final result = await likePost('p1');
    expect(result.isRight(), isTrue);
    verify(() => repository.likePost('p1')).called(1);
  });
}
```

**T17 Widget test helper** — `test/helpers/pump_app.dart`
```dart
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: EasyLocalization(
        supportedLocales: L10n.supportedLocales,
        path: L10n.path,
        fallbackLocale: L10n.fallbackLocale,
        startLocale: locale,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: AppTheme.light(),
            home: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

---

## 4. Design system spec

Material 3 (`useMaterial3: true`), explicit `ColorScheme` (never `fromSeed`). Custom tokens via `ThemeExtension<HalalColors>`. Access in widgets: `context.colors` (ColorScheme), `context.halal` (HalalColors), `context.text` (TextTheme) — extensions in `lib/core/utils/context_ext.dart`.

### 4.1 Color tokens (`lib/core/theme/app_colors.dart`)
| Token | ColorScheme / HalalColors field | Light | Dark |
|---|---|---|---|
| primary (deep green) | `primary` | `#0B5D3B` | `#3FA877` |
| onPrimary | `onPrimary` | `#FFFFFF` | `#04140C` |
| primaryContainer | `primaryContainer` | `#D5EBDF` | `#12422D` |
| onPrimaryContainer | `onPrimaryContainer` | `#052E1C` | `#CDEBDB` |
| gold (accent) | `secondary` + `HalalColors.gold` | `#B8964A` | `#D4B26A` |
| onGold | `onSecondary` | `#FFFFFF` | `#1E1606` |
| goldContainer | `secondaryContainer` | `#F3EAD3` | `#3D3218` |
| onGoldContainer | `onSecondaryContainer` | `#3A2C0A` | `#F3EAD3` |
| background/surface | `surface` | `#FFFFFF` | `#0B0F0D` |
| surfaceElevated (sheets, cards) | `surfaceContainer` | `#FFFFFF` | `#121815` |
| surfaceVariant (fields, buttons) | `surfaceContainerHighest` | `#F2F4F3` | `#1C2521` |
| textPrimary | `onSurface` | `#101814` | `#EEF2F0` |
| textSecondary | `onSurfaceVariant` | `#66716B` | `#9AA6A0` |
| divider | `outlineVariant` | `#E1E5E3` | `#26312C` |
| outline | `outline` | `#C3CAC6` | `#3A4741` |
| error | `error` | `#C62828` | `#EF6B5E` |
| onError | `onError` | `#FFFFFF` | `#1A0503` |
| like (heart) | `HalalColors.like` | `#E0344A` | `#FF5A6B` |
| success | `HalalColors.success` | `#2E7D32` | `#66BB6A` |
| storyRing (sweep gradient) | `HalalColors.storyRing` (List<Color>) | `#D4B26A, #B8964A, #0B5D3B, #D4B26A` | `#E2C483, #D4B26A, #3FA877, #E2C483` |
| seenRing | `HalalColors.seenRing` | `#C9CFCC` | `#3A4741` |
| badge (unread dot/count) | `HalalColors.badge` | `#E0344A` | `#FF5A6B` |
| onMedia (text/icons over photos/video) | `HalalColors.onMedia` | `#FFFFFF` | `#FFFFFF` |
| mediaScrim (gradient over media) | `HalalColors.mediaScrim` | `#99000000` | `#99000000` |
| skeletonBase | `HalalColors.skeleton` | `#ECEFED` | `#1F2824` |

Rules: gold is never used for body text (contrast < 4.5:1 on white); only rings, icons, banner accents. Reels and story viewer always use the dark theme (`Theme(data: AppTheme.dark(), ...)`).

### 4.2 Spacing, radii, sizes, durations
`AppSpacing` (double consts): `xxs 2`, `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`, `xxl 24`, `xxxl 32`, `huge 48`.
`AppRadii`: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `pill 999`. Also `BorderRadius` getters: `AppRadii.brSm` etc.
`AppDurations`: `fast 150ms`, `normal 250ms`, `slow 400ms`, `heartPop 700ms`, `debounce 300ms`, `storyImage 5000ms`, `snackbar 3000ms`.
`AppSizes` (all IG-equivalent measurements, logical px):
| Name | Value | Use |
|---|---|---|
| appBarHeight | 52 | all top bars |
| bottomNavHeight | 50 | + bottom safe area |
| navIcon | 26 | bottom nav icons |
| icon | 24 | app bar/action icons |
| iconSm | 16 | inline icons |
| iconXs | 14 | comment like heart, audio label |
| actionIcon | 26 | post action bar icons |
| reelActionIcon | 28 | reel side column |
| avatarXs | 24 | nav profile avatar (26 with ring) |
| avatarSm | 32 | post header, comments, reels author |
| avatarMd | 44 | lists (followers, search, inbox, notifications) |
| avatarLg | 62 | story avatar |
| avatarXl | 86 | profile header |
| storyRingWidth | 2.5 | |
| storyRingGap | 3 | |
| storyItemWidth | 76 | tray item incl. label |
| storiesBarHeight | 106 | |
| highlightCircle | 64 | |
| postHeaderHeight | 54 | |
| postActionBarHeight | 46 | |
| carouselDot | 6 | |
| buttonHeight | 44 | primary buttons (auth) |
| buttonHeightSm | 34 | profile buttons |
| followButtonReel | 28 | |
| inputHeight | 48 | text fields |
| commentInputHeight | 44 | |
| chatInputHeight | 52 | |
| bubbleMaxWidthFactor | 0.75 | chat bubble max width of screen |
| profileTabBarHeight | 44 | |
| gridSpacing | 1.5 | profile/explore grid |
| sheetHandleWidth | 36 | |
| sheetHandleHeight | 4 | |
| badgeDot | 8 | |
| badgeCountMin | 18 | |
| bannerHeight | 56 | occasion banner |
| maxContentWidth | 600 | center content on tablets |
| heartOverlay | 96 | double-tap heart |

### 4.3 Typography (`lib/core/theme/app_typography.dart`, family `Cairo`, `height: 1.35`)
| TextTheme slot | Size/Weight | Use |
|---|---|---|
| displaySmall | 28 / w700 | auth titles |
| headlineSmall | 22 / w700 | screen big titles |
| titleLarge | 20 / w700 | sheet titles |
| titleMedium | 16 / w700 | app bar titles, profile username |
| titleSmall | 14 / w700 | usernames in posts |
| bodyLarge | 16 / w400 | inputs |
| bodyMedium | 14 / w400 | captions, comments, bio |
| bodySmall | 12 / w400 | timestamps, secondary |
| labelLarge | 14 / w600 | buttons |
| labelMedium | 13 / w600 | stats labels, chips |
| labelSmall | 11 / w500 | badges, tiny meta |
| Wordmark (custom `AppTypography.wordmark`) | 24 / w800, color primary, letterSpacing 0 | home app bar |
| Stat number (`AppTypography.statNumber`) | 17 / w700 | profile counts |

### 4.4 Icons & brand
- Icon pack: `lucide_icons_flutter` (`LucideIcons.*`). Mapping: home `house`, explore `search`, create `squarePlus`, reels `clapperboard`, heart `heart`, comment `messageCircle`, share/DM `send`, save `bookmark`, more `ellipsis`, grid `grid3x3`, settings `settings`, lock `lock`, camera `camera`, image `image`, back `arrowLeft` (mirrored in RTL via `DirectionalIcon`), close `x`, mute `volumeX`, unmute `volume2`, audio `audioLines`, multi-image `copy`, eye `eye`, flag `flag`, block `ban`, moon `moon`, sun `sun`, globe `globe`, logout `logOut`.
- Active nav state: icon color `onSurface` + `AppSizes.badgeDot`-sized dot in `primary` under the icon; inactive `onSurfaceVariant`. Profile tab shows avatar (24) with 1.5px `onSurface` ring when active.
- Filled states: `HeartIcon(filled: bool, size)` → filled = Material `Icons.favorite` in `like` color, outline = `LucideIcons.heart` in current icon color. `BookmarkIcon(filled: bool, size)` → filled = `Icons.bookmark` in `onSurface`, outline = `LucideIcons.bookmark`. Material `Icons.*` are allowed ONLY inside these two widgets.
- Brand mark: original 8-point star (two overlapping squares) — `assets/brand/logo_mark.svg` (exact content in P1-T13). Wordmark = text `LocaleKeys.app_name` in `AppTypography.wordmark` preceded by the mark at 22px.

### 4.5 Layout specs (IG-equivalent)
- **Home app bar**: height 52, no elevation, background `surface`; start: mark + wordmark; end: heart (badge dot when unread notifications) then send icon (count badge when unread conversations), spacing `lg`.
- **Stories bar**: height 106, horizontal list, padding horizontal `md`, item spacing `md`; item = ring(62 avatar + gap 3 + ring 2.5) + label `bodySmall` max 1 line, width 76. First item "Your story" with a 20px `primary` plus badge at bottom-end. Unseen ring = sweep gradient `storyRing`; seen = 1px `seenRing`.
- **Occasion banner**: below stories bar, height 56, margin `md`, radius `md`, bg `secondaryContainer`, text `onSecondaryContainer` `labelLarge`, start icon `LucideIcons.moonStar` gold, end close `x`, subtitle Hijri date `bodySmall`.
- **Post card**: header 54 (padding h `md`; avatar 32; username `titleSmall`; location `bodySmall`; end `ellipsis`). Media: full width, `AspectRatio(post.aspectRatio)` (0.8–1.91), `PageView` for carousel, counter chip "1/3" top-end (`labelSmall`, scrim bg, radius pill). Action bar 46: heart, comment, send at start with spacing `lg`; dots centered (6px, active `primary`, inactive `outline`); bookmark at end. Then likes `titleSmall`; caption = username bold + text via `ReadMoreText` trimLines 2; "View all N comments" `bodyMedium` secondary; time `bodySmall` secondary (timeago). Bottom gap `md`.
- **Double-tap like**: white heart 96px centered, scale 0→1.2→1 + fade out, total 700ms (`flutter_animate`). Also sets like (never unlikes).
- **Profile**: padding `lg`; row avatar 86 + three stats (number `statNumber`, label `labelMedium`); full name `titleSmall`; bio `bodyMedium`; buttons row (two expanded buttons 34h, radius `sm`, bg `surfaceContainerHighest`, `labelLarge`) — own: Edit profile / Share profile; other: Follow(primary bg)/Following + Message. Highlights row circles 64 + label. Pinned `TabBar` 44: grid / reels / saved(own only); indicator 1.5px `onSurface`. Grid: 3 cols, spacing 1.5, square tiles; carousel tile shows `copy` icon top-end 16px `onMedia`. Reels tab: 3 cols aspect 9:16 with play icon.
- **Private profile (not following)**: header + stats shown, tabs replaced by lock icon 48 + `profile.private.title`/`subtitle`.
- **Comments sheet**: `DraggableScrollableSheet` initial 0.7, min 0.5, max 0.95, top radius `xl`; handle 36×4; title `titleMedium` centered; row: avatar 32, username `labelMedium` + time `bodySmall`, text `bodyMedium`, "Reply" `labelSmall` secondary; end heart 14 + count `labelSmall`; replies indented start 44 with "View N replies" line (24px divider dash). Input bar 44 with avatar 32, rounded field radius `xl`, "Post" text button `primary`; reply mode shows "Replying to @x" chip with close.
- **Reels**: full-screen vertical `PageView`, dark theme, `BoxFit.cover`; bottom scrim gradient; end column (bottom 96 from safe area) icons 28 + counts `labelSmall` `onMedia`: heart, comment, send, ellipsis; bottom-start: avatar 32 + username `titleSmall` + Follow outlined (28h, radius `sm`, border `onMedia`), caption 2 lines, audio row `audioLines` 14 + "Original audio"/"Muted". Tap = toggle mute (icon toast 600ms). Long-press = pause. 2px progress bar at bottom.
- **Story viewer**: `story_view` progress bars; header avatar 32 + username + relative time; end `x`. Owner: bottom "Seen by N" with `eye`, opens viewers sheet; ellipsis → delete / add to highlight.
- **Chat**: own bubble `primary`/`onPrimary` aligned end; other `surfaceContainerHighest`/`onSurface` aligned start; radius `AppRadii.xl`, padding h `md` v `sm`, max width 75%; time `labelSmall`; date separator chip. Input 52, radius pill, camera icon start, send text button end.
- **Bottom nav**: custom `HalalBottomNav`, height 50 + safe area, top border 0.5 `outlineVariant`, 5 equal items, no labels, `Semantics(label: ...)` for each.

### 4.6 Core widgets (`lib/core/widgets/`)
`app_avatar.dart` (AppAvatar: url?, size, fallback icon), `story_ring.dart` (StoryRing: child, seen, size), `app_network_image.dart` (wraps CachedNetworkImage, `memCacheWidth` = layout width × devicePixelRatio, skeleton placeholder, error icon), `halal_wordmark.dart`, `directional_icon.dart`, `heart_icon.dart`, `bookmark_icon.dart`, `app_button.dart` (AppButton.primary/secondary/text, loading state), `app_text_field.dart`, `loading_view.dart`, `error_view.dart` (error → `failureMessageKey`, retry), `empty_view.dart`, `app_snackbar.dart` (`showAppSnackBar(context, key)`), `confirm_dialog.dart`, `app_bottom_sheet.dart` (`showAppSheet`), `count_text.dart` (compact numbers), `badge_dot.dart`, `skeletons.dart` (PostCardSkeleton, ListTileSkeleton, GridSkeleton via `skeletonizer`), `hijri_date_text.dart`, `max_width_box.dart`. (The occasion banner is a feed widget, created in P4-T09 under `lib/features/feed/presentation/widgets/`.)

### 4.7 RTL & l10n notes
- `MaterialApp.router(locale: context.locale)` → RTL automatic for `ar`. Never wrap anything in `Directionality` except the `StoryView` widget, which is wrapped in `Directionality(textDirection: TextDirection.ltr)` because its tap zones/progress bars are LTR-only (known limitation, §11).
- Directional icons (back, chevrons, send) use `DirectionalIcon` (flips with `Transform.flip(flipX: isRtl)`).
- Numbers: `formatCompact(int, locale)` via `NumberFormat.compact(locale: languageCode)`. Dates: timeago with `ar`/`en` messages; full dates `DateFormat.yMMMMd(languageCode)` + Hijri via `formatHijri(date, languageCode)` → `'${h.hDay} ${h.longMonthName} ${h.hYear} ${suffix}'` where suffix = `LocaleKeys.common_hijri_suffix.tr()`.
- Usernames and URLs are LTR content: wrap usernames in `Text(..., textDirection: TextDirection.ltr)` only inside `@username` mentions in Arabic sentences — use `bidiSafe(String)` helper in formatters (`'\u2068$s\u2069'`).

---

## 5. Approved packages (verified on pub.dev 2026-10-13; resolve together on Dart 3.13.2 / Flutter 3.47.2)

### 5.1 dependencies
| Package | Version | Purpose |
|---|---|---|
| flutter_localizations (sdk) | — | Material/Cupertino localizations |
| cached_network_image | ^4.0.4 | network images with disk cache |
| easy_localization | ^3.0.8 | ar/en JSON translations, RTL, key codegen |
| fc_native_video_thumbnail | ^3.0.1 | reel thumbnail generation |
| flutter_animate | ^4.5.2 | heart pop, micro-animations |
| flutter_cache_manager | ^3.4.5 | shared cache config (video/image) |
| flutter_image_compress | ^2.5.1 | resize/compress before upload |
| flutter_riverpod | ^3.4.3 | state management |
| flutter_staggered_grid_view | ^0.7.0 | explore quilted grid (`SliverQuiltedGridDelegate`) |
| flutter_svg | ^2.3.0 | brand mark SVG |
| fpdart | ^1.2.0 | `Either`, `Unit` |
| freezed_annotation | ^3.1.0 | entities/models/failures |
| gap | ^3.0.1 | `Gap(AppSpacing.x)` spacing |
| go_router | ^18.0.2 | routing, shell, redirect |
| hijri | ^3.0.1 | Hijri calendar (Umm al-Qura) |
| image_cropper | ^13.0.0 | crop avatar (1:1 circle) and posts (1:1 / 4:5) |
| image_picker | ^1.2.4 | camera capture (photo/video) |
| infinite_scroll_pagination | ^5.1.1 | paged lists/grids |
| intl | ^0.20.2 | number/date formatting |
| json_annotation | ^4.12.0 | models |
| logger | ^2.8.0 | logging |
| lucide_icons_flutter | ^3.1.25 | icon pack |
| mime | ^2.1.0 | content types for uploads |
| package_info_plus | ^10.2.2 | version in settings |
| path | ^1.9.1 | file extensions |
| path_provider | ^2.1.6 | temp dirs for compression/thumbnails |
| permission_handler | ^13.0.2 | camera/mic status, open settings |
| photo_manager | ^3.12.0 | gallery assets (used by picker) |
| readmore | ^3.0.0 | caption "more" |
| riverpod_annotation | ^4.0.7 | provider codegen annotations |
| share_plus | ^13.3.1 | external share |
| shared_preferences | ^2.5.6 | theme mode, banner dismissals, recent searches, guidelines ack |
| skeletonizer | ^3.0.0 | loading skeletons |
| smooth_page_indicator | ^3.0.0 | carousel dots |
| story_view | ^0.16.6 | story player |
| supabase_flutter | ^2.18.3 | backend SDK |
| timeago | ^3.7.1 | relative times |
| url_launcher | ^6.3.3 | privacy/terms links |
| uuid | ^4.6.0 | client-side ids for storage paths |
| video_player | ^2.14.1 | reels playback |
| visibility_detector | ^0.4.0+2 | autoplay/pause videos by visibility |
| wechat_assets_picker | ^10.1.3 | IG-like multi-select gallery picker |

### 5.2 dev_dependencies
| Package | Version | Purpose |
|---|---|---|
| flutter_test (sdk) | — | tests |
| build_runner | ^2.16.2 | codegen |
| flutter_launcher_icons | ^0.14.4 | app icons |
| flutter_native_splash | ^2.4.8 | native splash |
| freezed | ^4.0.2 | codegen |
| json_serializable | ^6.14.1 | codegen |
| mocktail | ^1.0.5 | mocks |
| riverpod_generator | ^4.0.9 | provider codegen |
| very_good_analysis | ^11.0.0 | lints |

Analyzer plugin (NOT a pubspec entry): `riverpod_lint: 3.1.9` under `plugins:` in `analysis_options.yaml` (riverpod_lint 3 uses `analysis_server_plugin`).

### 5.3 Choices between alternatives (final)
| Picked | Over | Reason |
|---|---|---|
| video_player (custom overlay) | chewie, media_kit | Reels need no control chrome; media_kit adds heavy native libs and last released 2025-12 |
| story_view | flutter_story_presenter | wider adoption; API verified to compile |
| wechat_assets_picker (+image_picker for camera) | photo_manager-only custom grid, insta_assets_picker | ready IG-like multi-select grid, maintained (2026-07) |
| lucide_icons_flutter | iconsax_flutter | actively released (2026-10); clean outline style, distinct from IG icons |
| skeletonizer | shimmer | skeletons generated from real layouts, less code |
| bundled Cairo TTF | google_fonts | offline-first, deterministic, works in tests without network |
| `--dart-define-from-file` | envied | no codegen, keeps existing `String.fromEnvironment` config |
| riverpod_lint (analyzer plugin) | custom_lint | custom_lint 0.8.1 pins analyzer ^8 → conflicts with freezed 4 (analyzer ≥14) |
| route constants | go_router_builder | less codegen surface for executor agents |
| plain logical px tokens | flutter_screenutil | screenutil stale (2024-05) and scaling hurts accessibility/tablets |
| no video compression v1 | video_compress | stale (2025-02), AGP 9 risk; enforce 90s/100MB limits instead |

### 5.4 Legacy packages (present now; removed in P9-T09)
`cloud_firestore`, `firebase_auth`, `firebase_core`, `firebase_storage`, `date_format`, `flutter_screenutil`, `flutter_lints` (removed in P0-T07), `cupertino_icons` (removed P9-T09).

---

## 6. Database spec (Supabase Postgres)

### 6.0 Conventions (apply to every new migration)
- File header comment: `-- supabase/migrations/<file>` + one-line purpose.
- `CREATE TABLE public.<name>`; PK uuid `DEFAULT gen_random_uuid()` unless composite.
- Timestamps `TIMESTAMPTZ NOT NULL DEFAULT now()`. Mutable tables get `updated_at` + trigger `public.update_updated_at_column()` (exists, from 001).
- FKs to `public.profiles(id) ON DELETE CASCADE` unless stated.
- `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` for every new table. Policies `TO authenticated`, use `(select auth.uid())` (initplan-friendly).
- Functions: `SET search_path = public`. Helpers/RPCs that bypass RLS are `SECURITY DEFINER` and must check `auth.uid()` themselves. After each function: `REVOKE ALL ON FUNCTION public.<fn>(<argtypes>) FROM PUBLIC, anon; GRANT EXECUTE ON FUNCTION public.<fn>(<argtypes>) TO authenticated;` (exception: `is_username_available` also granted to `anon`).
- Never use `gen_random_bytes` (pgcrypto lives in `extensions` schema on Supabase); for random suffixes use `substr(md5(random()::text), 1, 6)`.
- Read RPCs: `LANGUAGE sql STABLE SECURITY INVOKER` (RLS applies), `RETURNS TABLE(...)` with columns exactly as listed. Limits clamped: `LEAST(GREATEST(p_limit,1),50)`.
- Keyset pagination: newest-first `WHERE p_before_created_at IS NULL OR (t.created_at, t.id) < (p_before_created_at, p_before_id) ORDER BY t.created_at DESC, t.id DESC`; oldest-first (replies, chat not used) mirror with `>` and `p_after_*`.
- Custom errors: `RAISE EXCEPTION 'blocked'|'not_found'|'private'|'invalid'` (client maps P0001 messages, §3.4 T2).

### 6.1 Tables
Legend: E = exists (001), M = modified (migration), N = new.

**profiles** (E, M in 005)
| Column | Type | Constraint |
|---|---|---|
| id | uuid | PK, FK auth.users ON DELETE CASCADE |
| username | citext | NOT NULL UNIQUE; CHECK `username ~* '^[a-z0-9_]{3,30}$'` NOT VALID (005) |
| full_name | text | NOT NULL DEFAULT '' CHECK char_length ≤ 60 (005) |
| bio | text | NOT NULL DEFAULT '' CHECK char_length ≤ 150 NOT VALID (005) |
| avatar_path | text | NULL (avatars bucket path) |
| is_private | boolean | NOT NULL DEFAULT false (005) |
| posts_count, reels_count, followers_count, following_count | integer | NOT NULL DEFAULT 0 CHECK ≥ 0 (005) |
| created_at, updated_at | timestamptz | |
Grants (005): `REVOKE UPDATE ON public.profiles FROM authenticated, anon; GRANT UPDATE (username, full_name, bio, avatar_path, is_private) ON public.profiles TO authenticated;`

**posts** (E, M in 005/007)
| Column | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK profiles |
| caption | text | NULL, CHECK char_length ≤ 2200 (005) |
| location | text | NULL, CHECK char_length ≤ 100 (005) |
| aspect_ratio | numeric(4,3) | NOT NULL DEFAULT 1.000 CHECK BETWEEN 0.800 AND 1.910 (005) |
| likes_count, comments_count | integer | NOT NULL DEFAULT 0 (005) |
| image_path | text | DROPPED in 007 after copying into post_media |
| created_at, updated_at | timestamptz | |
Grants (005): UPDATE only `(caption, location)`. Indexes exist.

**post_media** (N, 007)
| Column | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| post_id | uuid | NOT NULL FK posts ON DELETE CASCADE |
| user_id | uuid | NOT NULL FK profiles |
| position | smallint | NOT NULL CHECK 0–9; UNIQUE(post_id, position) |
| storage_path | text | NOT NULL (post-images bucket) |
| media_type | text | NOT NULL DEFAULT 'image' CHECK IN ('image') |
| width, height | integer | NULL CHECK > 0 |
| created_at | timestamptz | |
Index: `(post_id, position)` (covered by unique).

**reels** (E, M in 005)
Add: `thumbnail_path text NULL`, `duration_ms integer NULL CHECK BETWEEN 1 AND 90000`, `width integer NULL`, `height integer NULL`, `is_muted boolean NOT NULL DEFAULT false`, `likes_count integer NOT NULL DEFAULT 0`, `comments_count integer NOT NULL DEFAULT 0`; CHECK caption ≤ 2200. Grants: UPDATE only `(caption)`.

**post_likes**, **reel_likes** (E) — unchanged columns.

**post_comments** (E, M in 007)
Add: `parent_id uuid NULL REFERENCES public.post_comments(id) ON DELETE CASCADE`, `likes_count integer NOT NULL DEFAULT 0`, `replies_count integer NOT NULL DEFAULT 0`; CHECK `char_length(content) BETWEEN 1 AND 1000` NOT VALID. Index `(parent_id, created_at)`; index `(post_id, created_at DESC, id DESC) WHERE parent_id IS NULL`. Trigger `enforce_single_level_reply` BEFORE INSERT: if parent_id not null, parent must exist, same post_id, parent.parent_id IS NULL, else `RAISE EXCEPTION 'invalid'`. Grants: UPDATE only `(content)`.

**reel_comments** (E, M in 007): CHECK content 1–1000 NOT VALID; index `(reel_id, created_at DESC, id DESC)`. Grants UPDATE `(content)`.

**comment_likes** (N, 007): `comment_id uuid FK post_comments ON DELETE CASCADE`, `user_id uuid FK profiles`, `created_at`; PK(comment_id, user_id); index (user_id).

**saved_posts** (N, 007): `user_id uuid FK profiles`, `post_id uuid FK posts ON DELETE CASCADE`, `created_at`; PK(user_id, post_id); index (user_id, created_at DESC).

**follows** (E) — unchanged columns.

**follow_requests** (N, 005): `requester_id uuid FK profiles`, `target_id uuid FK profiles`, `created_at`; PK(requester_id, target_id); CHECK requester_id <> target_id; index (target_id, created_at DESC).

**blocks** (N, 004): `blocker_id uuid FK profiles`, `blocked_id uuid FK profiles`, `created_at`; PK(blocker_id, blocked_id); CHECK blocker_id <> blocked_id; index (blocked_id). Trigger AFTER INSERT `on_block_cleanup` (SECURITY DEFINER): delete follows both directions and follow_requests both directions between the pair.

**reports** (N, 004)
| Column | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| reporter_id | uuid | NOT NULL FK profiles |
| target_type | text | NOT NULL CHECK IN ('post','reel','post_comment','reel_comment','user','story','message') |
| target_id | uuid | NOT NULL |
| reason | text | NOT NULL CHECK IN ('spam','nudity','hate','violence','harassment','false_info','music','other') |
| details | text | NOT NULL DEFAULT '' CHECK ≤ 500 |
| status | text | NOT NULL DEFAULT 'open' CHECK IN ('open','reviewed','dismissed','actioned') |
| created_at | timestamptz | |
UNIQUE(reporter_id, target_type, target_id); index (status, created_at DESC).

**stories** (N, 008)
| Column | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK profiles |
| media_path | text | NOT NULL (story-media bucket) |
| media_type | text | NOT NULL CHECK IN ('image','video') |
| duration_ms | integer | NOT NULL DEFAULT 5000 CHECK BETWEEN 1000 AND 30000 |
| created_at | timestamptz | |
| expires_at | timestamptz | NOT NULL DEFAULT now() + interval '24 hours' |
Indexes: (user_id, created_at DESC), (expires_at).

**story_views** (N, 008): `story_id uuid FK stories ON DELETE CASCADE`, `viewer_id uuid FK profiles`, `viewed_at timestamptz DEFAULT now()`; PK(story_id, viewer_id); index (viewer_id).

**highlights** (N, 008): `id uuid PK`, `user_id uuid FK profiles`, `title text NOT NULL CHECK char_length BETWEEN 1 AND 30`, `cover_story_id uuid NULL FK stories ON DELETE SET NULL`, `created_at`, `updated_at` (+trigger); index (user_id, created_at).

**highlight_items** (N, 008): `highlight_id uuid FK highlights ON DELETE CASCADE`, `story_id uuid FK stories ON DELETE CASCADE`, `user_id uuid FK profiles`, `position smallint NOT NULL DEFAULT 0`, `created_at`; PK(highlight_id, story_id); index (story_id).

**conversations** (N, 009): `id uuid PK`, `direct_key text NOT NULL UNIQUE` (= `least(a,b)::text || ':' || greatest(a,b)::text`), `created_at`, `last_message_at timestamptz NULL`, `last_message_preview text NOT NULL DEFAULT ''` (first 80 chars of text; '' for image/post), `last_message_kind text NULL CHECK IN ('text','image','post')`, `last_sender_id uuid NULL FK profiles ON DELETE SET NULL`. Index (last_message_at DESC).

**conversation_members** (N, 009): `conversation_id uuid FK conversations ON DELETE CASCADE`, `user_id uuid FK profiles`, `joined_at timestamptz DEFAULT now()`, `last_read_at timestamptz NOT NULL DEFAULT now()`; PK(conversation_id, user_id); index (user_id).

**messages** (N, 009)
| Column | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| conversation_id | uuid | NOT NULL FK conversations ON DELETE CASCADE |
| sender_id | uuid | NOT NULL FK profiles |
| kind | text | NOT NULL CHECK IN ('text','image','post') |
| body | text | NULL CHECK char_length ≤ 2000 |
| media_path | text | NULL (chat-media bucket) |
| shared_post_id | uuid | NULL FK posts ON DELETE SET NULL |
| created_at | timestamptz | |
CHECK `(kind <> 'text' OR char_length(coalesce(body,'')) >= 1) AND (kind <> 'image' OR media_path IS NOT NULL)`. Index (conversation_id, created_at DESC, id DESC). Trigger AFTER INSERT `on_message_inserted` (SECURITY DEFINER): update conversation `last_message_at = NEW.created_at, last_message_preview = CASE kind WHEN 'text' THEN left(body,80) ELSE '' END, last_message_kind, last_sender_id`; set sender's `conversation_members.last_read_at = NEW.created_at`.

**notifications** (N, 010)
| Column | Type | Constraint |
|---|---|---|
| id | uuid | PK |
| recipient_id | uuid | NOT NULL FK profiles |
| actor_id | uuid | NOT NULL FK profiles |
| type | text | NOT NULL CHECK IN ('post_like','post_comment','comment_reply','comment_like','reel_like','reel_comment','follow','follow_request','follow_accept') |
| post_id | uuid | NULL FK posts ON DELETE CASCADE |
| reel_id | uuid | NULL FK reels ON DELETE CASCADE |
| comment_id | uuid | NULL (no FK; may reference post_comments or reel_comments) |
| created_at | timestamptz | |
| read_at | timestamptz | NULL |
Indexes: (recipient_id, created_at DESC, id DESC); partial (recipient_id) WHERE read_at IS NULL. Grants: `REVOKE INSERT, UPDATE ON public.notifications FROM authenticated, anon; GRANT UPDATE (read_at) ON public.notifications TO authenticated;`

### 6.2 RLS policy summary (all `TO authenticated`; `uid` = `(select auth.uid())`)
Helper functions (006, `STABLE SECURITY DEFINER`):
```sql
-- is_blocked_between(a uuid, b uuid) -> boolean : EXISTS block in either direction
-- is_following(p_follower uuid, p_target uuid) -> boolean
-- can_view_user(p_target uuid) -> boolean
CREATE OR REPLACE FUNCTION public.can_view_user(p_target uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p_target = auth.uid()
      OR (NOT public.is_blocked_between(auth.uid(), p_target)
          AND (NOT COALESCE((SELECT is_private FROM public.profiles WHERE id = p_target), true)
               OR public.is_following(auth.uid(), p_target)));
$$;
-- can_view_post(p_post_id uuid) -> EXISTS(SELECT 1 FROM posts WHERE id = p_post_id AND can_view_user(user_id))
-- can_view_reel(p_reel_id uuid) -> same for reels
-- is_private_user(p_user uuid) -> COALESCE(is_private,false)
-- is_conversation_member(p_conversation_id uuid) -> boolean  (009)
```
| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| profiles | `NOT EXISTS (blocks WHERE blocker_id = profiles.id AND blocked_id = uid)` (replaces profiles_select_all) | own (existing) | own (existing) + column grants | none |
| posts | `can_view_user(user_id)` (replaces posts_select_all) | own (existing) | own | own |
| post_media | `can_view_post(post_id)` | `user_id = uid AND EXISTS(posts p WHERE p.id = post_id AND p.user_id = uid)` | none | own |
| reels | `can_view_user(user_id)` | own | own | own |
| post_likes | `can_view_post(post_id)` | `user_id = uid AND can_view_post(post_id)` | none | own |
| reel_likes | `can_view_reel(reel_id)` | `user_id = uid AND can_view_reel(reel_id)` | none | own |
| post_comments | `can_view_post(post_id)` | `user_id = uid AND can_view_post(post_id)` | own | own OR post owner (existing) |
| reel_comments | `can_view_reel(reel_id)` | `user_id = uid AND can_view_reel(reel_id)` | own | own OR reel owner |
| comment_likes | `EXISTS(post_comments c WHERE c.id = comment_id AND can_view_post(c.post_id))` | `user_id = uid AND` same EXISTS | none | own |
| saved_posts | `user_id = uid` | `user_id = uid AND can_view_post(post_id)` | none | own |
| follows | `can_view_user(follower_id) OR can_view_user(following_id)` | `follower_id = uid AND NOT is_private_user(following_id) AND NOT is_blocked_between(uid, following_id)` | none | `follower_id = uid OR following_id = uid` |
| follow_requests | `requester_id = uid OR target_id = uid` | `requester_id = uid AND is_private_user(target_id) AND NOT is_blocked_between(uid, target_id)` | none | `requester_id = uid OR target_id = uid` |
| blocks | `blocker_id = uid` | `blocker_id = uid` | none | `blocker_id = uid` |
| reports | `reporter_id = uid` | `reporter_id = uid AND status = 'open'` | none | none |
| stories | `user_id = uid OR (can_view_user(user_id) AND (expires_at > now() OR EXISTS(highlight_items hi WHERE hi.story_id = stories.id)))` | own | none | own |
| story_views | `viewer_id = uid OR EXISTS(stories s WHERE s.id = story_id AND s.user_id = uid)` | `viewer_id = uid` (via RPC) | none | none |
| highlights | `can_view_user(user_id)` | own | own | own |
| highlight_items | `can_view_user(user_id)` | `user_id = uid AND highlight & story both owned by uid` | none | own |
| conversations | `is_conversation_member(id)` | none (RPC) | none | none |
| conversation_members | `is_conversation_member(conversation_id)` | none (RPC) | none | none |
| messages | `is_conversation_member(conversation_id)` | `sender_id = uid AND is_conversation_member(conversation_id) AND NOT EXISTS(other member m WHERE is_blocked_between(uid, m.user_id))` | none | `sender_id = uid` |
| notifications | `recipient_id = uid` | none (triggers) | `recipient_id = uid` (column grant read_at) | `recipient_id = uid` |
Existing select policies to DROP in 006: `profiles_select_all, posts_select_all, reels_select_all, post_likes_select_all, reel_likes_select_all, post_comments_select_all, reel_comments_select_all, follows_select_all`; existing insert policies to DROP and recreate stricter: `post_likes_insert_own, reel_likes_insert_own, post_comments_insert_own, reel_comments_insert_own, follows_insert_own`; `follows_delete_own` replaced by `follows_delete_own_or_target`.

### 6.3 Triggers
| Name | Table / event | Function (SECURITY DEFINER) | Effect |
|---|---|---|---|
| on_auth_user_created | auth.users AFTER INSERT | handle_new_user v2 (005) | username from `raw_user_meta_data->>'username'` if matches `^[a-z0-9_]{3,30}$`, not reserved, not taken; else email prefix sanitized; on conflict suffix `'_' || substr(md5(random()::text),1,6)` with base truncated to 23 chars; `full_name` = left(meta full_name, 60) |
| trg_block_cleanup | blocks AFTER INSERT | on_block_cleanup (004) | remove follows/requests both ways |
| trg_single_level_reply | post_comments BEFORE INSERT | enforce_single_level_reply (007) | depth ≤ 1 |
| trg_message_inserted | messages AFTER INSERT | on_message_inserted (009) | conversation summary, sender read |
| trg_counts_* | see below (011) | `bump_count` style functions | counters |
| trg_notify_* | see below (010) | notify functions | notifications |
| trigger_*_updated_at | highlights BEFORE UPDATE | update_updated_at_column | |

Counters (011; `GREATEST(x - 1, 0)` on decrement; one function per table pair; backfill with UPDATE … FROM (SELECT count …) at end of 011):
- post_likes INS/DEL → posts.likes_count
- post_comments INS/DEL → posts.comments_count; if parent_id not null → parent.replies_count
- comment_likes INS/DEL → post_comments.likes_count
- reel_likes INS/DEL → reels.likes_count; reel_comments INS/DEL → reels.comments_count
- follows INS/DEL → profiles.following_count (follower) and followers_count (following)
- posts INS/DEL → profiles.posts_count; reels INS/DEL → profiles.reels_count
Pattern:
```sql
CREATE OR REPLACE FUNCTION public.count_post_likes() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
  ELSE
    UPDATE public.posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER trg_counts_post_likes AFTER INSERT OR DELETE ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.count_post_likes();
```
Note: counter UPDATEs fire `update_updated_at_column` on posts/profiles — acceptable.

Notifications (010; helper `create_notification(p_recipient, p_actor, p_type, p_post, p_reel, p_comment)` inserts unless recipient = actor or `is_blocked_between`):
| Trigger | Event | Notification |
|---|---|---|
| trg_notify_post_like | post_likes INSERT | post owner ← 'post_like' (post_id) |
| trg_notify_post_like_del | post_likes DELETE | delete matching 'post_like' (recipient, actor, post) |
| trg_notify_post_comment | post_comments INSERT | parent_id NULL → post owner 'post_comment'; else parent author 'comment_reply' (post_id, comment_id) |
| trg_notify_comment_like | comment_likes INSERT | comment author 'comment_like' (post_id, comment_id) |
| trg_notify_reel_like | reel_likes INSERT | reel owner 'reel_like'; DELETE removes it |
| trg_notify_reel_comment | reel_comments INSERT | reel owner 'reel_comment' |
| trg_notify_follow | follows INSERT | following_id ← 'follow'; DELETE removes 'follow' |
| trg_notify_follow_request | follow_requests INSERT | target ← 'follow_request'; DELETE removes it |
| (inside accept_follow_request) | — | requester ← 'follow_accept' (actor = target) |

### 6.4 RPC signatures (exact; all `p_limit` clamped 1–50)
Shared row shape **feed_post**: `post_id uuid, author_id uuid, author_username text, author_full_name text, author_avatar_path text, caption text, location text, aspect_ratio double precision, likes_count int, comments_count int, created_at timestamptz, media jsonb /* [{"path":..,"width":..,"height":..,"position":..}] ordered by position */, is_liked boolean, is_saved boolean`.
Shared **grid_item**: `post_id uuid, cover_path text, media_count int, created_at timestamptz`.
Shared **reel_row**: `reel_id uuid, author_id uuid, author_username text, author_avatar_path text, video_path text, thumbnail_path text, caption text, duration_ms int, width int, height int, is_muted boolean, likes_count int, comments_count int, created_at timestamptz, is_liked boolean, is_following_author boolean`.
Shared **comment_row**: `comment_id uuid, parent_id uuid, author_id uuid, author_username text, author_avatar_path text, content text, likes_count int, replies_count int, created_at timestamptz, is_liked boolean`.
Shared **user_row**: `id uuid, username text, full_name text, avatar_path text, is_private boolean, is_following boolean, created_at timestamptz /* relation time for lists; profile created_at for search */`.

| Migration | Function | Returns | Security | Semantics |
|---|---|---|---|---|
| 013 | `is_username_available(p_username text)` | boolean | DEFINER, anon+auth | regex valid, not reserved, not taken (case-insensitive) |
| 013 | `get_profile(p_user_id uuid)` | TABLE(id, username, full_name, bio, avatar_path, is_private, posts_count, reels_count, followers_count, following_count, created_at, is_me bool, is_following bool, is_requested bool, follows_me bool, is_blocked_by_me bool, can_view bool, has_active_story bool) | DEFINER (must work for private profiles; returns 0 rows if target blocked viewer) | |
| 013 | `search_profiles(p_query text, p_limit int DEFAULT 20)` | SETOF user_row | INVOKER | trim; escape `%`/`_`; `username ILIKE q||'%' OR full_name ILIKE q||'%'`; exclude self; order exact-match first then followers_count DESC |
| 013 | `get_home_feed(p_limit int DEFAULT 10, p_before_created_at timestamptz DEFAULT NULL, p_before_id uuid DEFAULT NULL)` | SETOF feed_post | INVOKER | posts by self + followed users; keyset newest-first |
| 013 | `get_post(p_post_id uuid)` | SETOF feed_post (0/1 row) | INVOKER | |
| 013 | `get_explore_posts(p_limit int DEFAULT 30, p_before_created_at, p_before_id)` | SETOF grid_item | INVOKER | authors not private, not self |
| 013 | `get_user_posts(p_user_id uuid, p_limit int DEFAULT 24, p_before_created_at, p_before_id)` | SETOF grid_item | INVOKER | |
| 013 | `get_saved_posts(p_limit int DEFAULT 24, p_before_created_at, p_before_id)` | SETOF grid_item (created_at = saved time) | INVOKER | keyset on saved_posts.created_at, post_id |
| 013 | `get_reels_feed(p_limit int DEFAULT 5, p_before_created_at, p_before_id)` | SETOF reel_row | INVOKER | all visible reels newest-first |
| 013 | `get_user_reels(p_user_id uuid, p_limit int DEFAULT 24, p_before_created_at, p_before_id)` | SETOF reel_row | INVOKER | |
| 014 | `create_post(p_post_id uuid, p_caption text, p_location text, p_aspect_ratio double precision, p_media jsonb)` | uuid | INVOKER | 1–10 media items `{path,width,height}`; inserts post then post_media positions 0..n-1 in one transaction; RAISE 'invalid' otherwise |
| 014 | `follow_user(p_target uuid)` | text ('following' / 'requested') | DEFINER | uid not null, not self (`invalid`), not blocked (`blocked`); private & not following → insert request ON CONFLICT DO NOTHING; else insert follow ON CONFLICT DO NOTHING |
| 014 | `unfollow_user(p_target uuid)` | void | DEFINER | delete follow + own request |
| 014 | `accept_follow_request(p_requester uuid)` | void | DEFINER | request must exist with target = uid (`not_found`); insert follow; delete request; notify 'follow_accept' |
| 014 | `decline_follow_request(p_requester uuid)` | void | DEFINER | delete request where target = uid |
| 014 | `remove_follower(p_follower uuid)` | void | DEFINER | delete follows(p_follower → uid) |
| 014 | `get_followers(p_user_id uuid, p_limit int DEFAULT 30, p_before_created_at, p_before_id)` | SETOF user_row | INVOKER | requires `can_view_user(p_user_id)` else empty; cursor on follows.created_at + follower id |
| 014 | `get_following(p_user_id uuid, p_limit, p_before_created_at, p_before_id)` | SETOF user_row | INVOKER | mirror |
| 014 | `get_follow_requests(p_limit int DEFAULT 30, p_before_created_at, p_before_id)` | SETOF user_row | INVOKER | requests where target = uid |
| 014 | `get_post_comments(p_post_id uuid, p_limit int DEFAULT 20, p_before_created_at, p_before_id)` | SETOF comment_row | INVOKER | top-level only, newest-first |
| 014 | `get_comment_replies(p_parent_id uuid, p_limit int DEFAULT 20, p_after_created_at timestamptz DEFAULT NULL, p_after_id uuid DEFAULT NULL)` | SETOF comment_row | INVOKER | oldest-first |
| 014 | `get_reel_comments(p_reel_id uuid, p_limit int DEFAULT 20, p_before_created_at, p_before_id)` | SETOF comment_row (parent_id NULL, likes 0, replies 0, is_liked false) | INVOKER | newest-first |
| 014 | `get_stories_tray()` | TABLE(user_id uuid, username text, avatar_path text, latest_story_at timestamptz, has_unseen boolean, is_me boolean) | INVOKER | users = self + followed, with ≥1 story where expires_at > now(); order is_me DESC, has_unseen DESC, latest_story_at DESC; max 100 |
| 014 | `get_user_stories(p_user_id uuid)` | TABLE(story_id uuid, media_path text, media_type text, duration_ms int, created_at timestamptz, expires_at timestamptz, is_viewed boolean, view_count int) | INVOKER | active only, oldest-first; view_count only when owner else 0 |
| 014 | `mark_story_viewed(p_story_id uuid)` | void | INVOKER | insert story_views(uid) ON CONFLICT DO NOTHING; skip if owner |
| 014 | `get_story_viewers(p_story_id uuid)` | SETOF user_row (created_at = viewed_at) | DEFINER | only story owner else `RAISE 'not_found'` |
| 014 | `get_my_story_archive(p_limit int DEFAULT 30, p_before_created_at, p_before_id)` | TABLE(story_id, media_path, media_type, duration_ms, created_at, expires_at, is_viewed, view_count) | INVOKER | all own stories incl. expired |
| 014 | `get_user_highlights(p_user_id uuid)` | TABLE(highlight_id uuid, title text, cover_path text, item_count int, created_at timestamptz) | INVOKER | cover_path = cover story media_path or first item's |
| 014 | `get_highlight_stories(p_highlight_id uuid)` | same columns as get_user_stories | INVOKER | ordered by position |
| 014 | `save_highlight(p_highlight_id uuid, p_title text, p_story_ids uuid[])` | uuid | INVOKER | p_highlight_id NULL → create; else replace title + items (positions by array order); all stories must be own; cover = first |
| 015 | `get_or_create_direct_conversation(p_other uuid)` | uuid | DEFINER | not self, not blocked; find by direct_key or create conversation + 2 members |
| 015 | `get_conversations(p_limit int DEFAULT 20, p_before_last_message_at timestamptz DEFAULT NULL, p_before_id uuid DEFAULT NULL)` | TABLE(conversation_id uuid, other_user_id uuid, other_username text, other_full_name text, other_avatar_path text, last_message_at timestamptz, last_message_preview text, last_message_kind text, last_sender_id uuid, is_unread boolean) | INVOKER | only conversations with ≥1 message; is_unread = last_message_at > my last_read_at AND last_sender_id <> uid |
| 015 | `get_messages(p_conversation_id uuid, p_limit int DEFAULT 30, p_before_created_at, p_before_id)` | TABLE(message_id uuid, conversation_id uuid, sender_id uuid, kind text, body text, media_path text, shared_post_id uuid, shared_post_cover_path text, shared_post_author_username text, created_at timestamptz) | INVOKER | newest-first |
| 015 | `mark_conversation_read(p_conversation_id uuid)` | void | DEFINER | member only; last_read_at = now() |
| 015 | `get_notifications(p_limit int DEFAULT 30, p_before_created_at, p_before_id)` | TABLE(notification_id uuid, type text, actor_id uuid, actor_username text, actor_avatar_path text, post_id uuid, post_cover_path text, reel_id uuid, reel_thumbnail_path text, comment_id uuid, created_at timestamptz, read_at timestamptz, is_following_actor boolean) | INVOKER | newest-first |
| 015 | `mark_notifications_read()` | void | INVOKER | set read_at = now() where recipient = uid and read_at null |
| 015 | `get_unread_counts()` | TABLE(notifications int, conversations int) | INVOKER | |
| 017 | `delete_my_account()` | void | DEFINER | `DELETE FROM auth.users WHERE id = auth.uid()` (cascades) |

Reference SQL for the feed (executor copies this shape for other feed_post RPCs):
```sql
CREATE OR REPLACE FUNCTION public.get_home_feed(
  p_limit int DEFAULT 10,
  p_before_created_at timestamptz DEFAULT NULL,
  p_before_id uuid DEFAULT NULL
) RETURNS TABLE (
  post_id uuid, author_id uuid, author_username text, author_full_name text,
  author_avatar_path text, caption text, location text, aspect_ratio double precision,
  likes_count int, comments_count int, created_at timestamptz, media jsonb,
  is_liked boolean, is_saved boolean
) LANGUAGE sql STABLE SECURITY INVOKER SET search_path = public AS $$
  SELECT p.id, p.user_id, pr.username::text, pr.full_name, pr.avatar_path,
         p.caption, p.location, p.aspect_ratio::double precision,
         p.likes_count, p.comments_count, p.created_at,
         COALESCE((SELECT jsonb_agg(jsonb_build_object(
                     'path', m.storage_path, 'width', m.width,
                     'height', m.height, 'position', m.position)
                   ORDER BY m.position)
                   FROM public.post_media m WHERE m.post_id = p.id), '[]'::jsonb),
         EXISTS (SELECT 1 FROM public.post_likes l
                 WHERE l.post_id = p.id AND l.user_id = auth.uid()),
         EXISTS (SELECT 1 FROM public.saved_posts s
                 WHERE s.post_id = p.id AND s.user_id = auth.uid())
  FROM public.posts p
  JOIN public.profiles pr ON pr.id = p.user_id
  WHERE (p.user_id = auth.uid()
         OR EXISTS (SELECT 1 FROM public.follows f
                    WHERE f.follower_id = auth.uid() AND f.following_id = p.user_id))
    AND (p_before_created_at IS NULL
         OR (p.created_at, p.id) < (p_before_created_at, p_before_id))
  ORDER BY p.created_at DESC, p.id DESC
  LIMIT LEAST(GREATEST(p_limit, 1), 50);
$$;
```

### 6.5 Storage buckets
| Bucket | Public | Size limit | MIME | Path | Policies |
|---|---|---|---|---|---|
| avatars (E) | yes | 5 MB | jpeg,png,webp | `{uid}/{uuid}.jpg` | existing (owner prefix) |
| post-images (E) | yes | 10 MB | jpeg,png,webp | `{uid}/{post_id}/{position}_{uuid}.jpg` | existing |
| reel-videos (E, M 012) | yes | 100 MB | mp4, quicktime, **+ image/jpeg** (thumbnails) | `{uid}/{reel_id}/video_{uuid}.mp4`, `{uid}/{reel_id}/thumb_{uuid}.jpg` | existing |
| story-media (N 012) | yes | 50 MB | jpeg,png,webp,mp4,quicktime | `{uid}/{story_id}/{uuid}.{jpg|mp4}` | public read; insert/update/delete owner prefix (same pattern as post-images) |
| chat-media (N 012) | **no** (signed URLs, TTL 3600s) | 10 MB | jpeg,png,webp | `{uid}/{conversation_id}/{uuid}.jpg` | SELECT: `bucket_id='chat-media' AND is_conversation_member(((storage.foldername(name))[2])::uuid)`; INSERT: owner prefix AND member of segment [2]; DELETE: owner prefix |
Public-bucket caveat: media of private accounts is unlisted but reachable by URL (documented risk §11).

### 6.6 Realtime (016)
`ALTER PUBLICATION supabase_realtime ADD TABLE public.messages, public.notifications;` (RLS applies to subscribers).

### 6.7 Migration file list (fixed names)
| File | Task | Content |
|---|---|---|
| 004_moderation_blocks_reports.sql | P2-T01 | blocks, reports, trg_block_cleanup, RLS |
| 005_profiles_privacy_counters.sql | P2-T02 | profiles/posts/reels new columns & checks, follow_requests (+RLS), handle_new_user v2, column grants |
| 006_visibility_helpers_policies.sql | P2-T03 | helper fns, drop/recreate policies on existing tables |
| 007_post_media_saved_comments.sql | P2-T04 | post_media (+data copy, drop image_path), saved_posts, comment parent/likes, comment_likes, reel_comments check |
| 008_stories_highlights.sql | P2-T05 | stories, story_views, highlights, highlight_items |
| 009_chat.sql | P2-T06 | conversations, members, messages, is_conversation_member, trigger |
| 010_notifications.sql | P2-T07 | notifications table, create_notification, notify triggers |
| 011_counters.sql | P2-T08 | counter triggers + backfill |
| 012_storage_v2.sql | P2-T09 | story-media, chat-media, reel-videos mime update + policies |
| 013_rpc_read.sql | P2-T10 | read RPCs (profile/search/feed/explore/grids/reels) |
| 014_rpc_social.sql | P2-T11 | create_post, follow*, comments, stories, highlights RPCs |
| 015_rpc_chat_notifications.sql | P2-T12 | chat + notification RPCs |
| 016_realtime.sql | P2-T12 | publication |
| 017_account_deletion.sql | P9-T06 | delete_my_account |
| `supabase/seed/qa_seed.sql` | P2-T14 | owner-run seed; not a migration |

---

## 7. Phased task list

Task block format: **Read** (files to read) · **Files** (C = create, M = modify, D = delete) · **Steps** · **Accept** (checkable) · **Verify** · **Commit** (exact message). Every task also implies contract MUST 7–8 (tick + log + commit).

Legacy inventory (Flutter code from the old app) and when it dies:
| Path | Deleted in |
|---|---|
| `lib/auth/auth_screen.dart`, `lib/auth/mainpage.dart`, `lib/widgets/navigation.dart`, `lib/core/auth/auth_service.dart`, `lib/screen/login_screen.dart`, `lib/screen/signup.dart`, `lib/screen/profile_screen.dart`, `lib/data/supabase_service/supabase_profile.dart`, `lib/data/model/user_profile.dart`, `lib/data/model/usermodel.dart`, `test/user_profile_test.dart` | P3-T12 |
| `lib/screen/add_post_screen.dart`, `lib/screen/addpost_text.dart`, `lib/screen/add_screen.dart`, `lib/screen/home.dart`, `lib/screen/post_screen.dart`, `lib/widgets/comment.dart`, `lib/widgets/like_animation.dart`, `lib/widgets/post_widget.dart`, `lib/util/*` (4 files), `lib/data/supabase_service/supabase_posts.dart`, `lib/data/model/post.dart`, `lib/core/database/supabase_client.dart`, `lib/core/config/supabase_config.dart` | P4-T14 |
| `lib/screen/add_reels_screen.dart`, `lib/screen/reelsScreen.dart`, `lib/screen/reels_edite_Screen.dart`, `lib/widgets/reels_item.dart` | P6-T08 |
| `lib/screen/explor_screen.dart`, `lib/screen/explore.dart` | P7-T08 |
| `lib/data/firebase_service/*` (3 files), `lib/firebase_options.dart`, `android/app/google-services.json`, `images/` (all), `web/`, `linux/`, `macos/`, `windows/`, `instagram_new.iml`, `android/instagram_new_android.iml` | P9-T09 |
| `android/app/src/main/kotlin/com/example/**` (3 MainActivity files) | P0-T05 |
| `SUPABASE_SETUP.md` (rewritten), `README.md` (rewritten) | P9-T14 |

---

### Phase 0 — Safety & setup
Note: until P0-T07 is done, `fvm flutter analyze` must show 0 **errors** (infos/warnings from legacy code allowed). From P0-T07 on: 0 issues.

#### [x] P0-T01 — Snapshot current state on a new branch
- **Read**: none. **Files**: none (git only) + this plan.
- **Steps**:
  1. `cd "$ROOT" && git status --short` (expect many M/D/?? entries — that is the uncommitted work to preserve).
  2. Confirm no secret files exist: `ls env 2>/dev/null; ls android/key.properties 2>/dev/null` → both print nothing. If anything prints → STOP.
  3. `git checkout -b halalgram/v1`
  4. `git add -A && git commit -m "chore(repo): P0-T01 snapshot pre-Halalgram state"`
- **Accept**: `git branch --show-current` = `halalgram/v1`; `git status --short` empty.
- **Verify**: `git log --oneline -1`.
- **Commit**: as in step 4 (the plan file tick goes in the next commit together with P0-T02).

#### [x] P0-T02 — Extend .gitignore
- **Read**: `.gitignore`. **Files**: M `.gitignore`.
- **Steps**: append exactly:
  ```
  # Halalgram
  env/*.json
  !env/example.json
  !env/ci.json
  coverage/
  android/key.properties
  *.jks
  *.keystore
  supabase/.temp/
  supabase/.branches/
  ```
- **Accept**: `git check-ignore env/dev.json` prints `env/dev.json`; `git check-ignore env/example.json` prints nothing.
- **Verify**: commands in Accept.
- **Commit**: `chore(repo): P0-T02 ignore env, keystores, supabase temp`

#### [x] P0-T03 — Create AI rule files
- **Read**: §9 of this plan. **Files**: C `.cursor/rules/halalgram-core.mdc`, C `.cursor/rules/halalgram-features.mdc`, C `.cursor/rules/halalgram-migrations.mdc`, C `AGENTS.md`.
- **Steps**: write each file with the exact contents from §9.1–§9.4.
- **Accept**: 4 files exist; `wc -l .cursor/rules/halalgram-core.mdc` < 60.
- **Verify**: `ls .cursor/rules AGENTS.md`.
- **Commit**: `docs(agents): P0-T03 add Halalgram agent rules`

#### [x] P0-T04 — Rename Dart package to `halalgram`
- **Read**: `pubspec.yaml` (first 25 lines). **Files**: M `pubspec.yaml`, M every `lib/**.dart` and `test/**.dart` containing `package:flutter_instagram_clone/`.
- **Steps**:
  1. In `pubspec.yaml` set `name: halalgram` and `description: "Halalgram — a modest social app."`.
  2. `grep -rl "package:flutter_instagram_clone/" lib test | xargs sed -i '' 's#package:flutter_instagram_clone/#package:halalgram/#g'`
  3. `fvm flutter pub get`
- **Accept**: `grep -r "flutter_instagram_clone" lib test pubspec.yaml` prints nothing; analyze shows 0 errors.
- **Verify**: `fvm flutter analyze | grep -c " error "` → `0`.
- **Commit**: `chore(repo): P0-T04 rename dart package to halalgram`

#### [x] P0-T05 — Rename Android app to com.halalgram.app
- **Read**: `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `android/app/src/main/AndroidManifest.xml`. **Files**: M those 3; C `android/app/src/main/kotlin/com/halalgram/app/MainActivity.kt`; C `android/app/src/main/res/values/strings.xml`; C `android/app/src/main/res/values-ar/strings.xml`; D `android/app/src/main/kotlin/com/example/` (whole folder).
- **Steps**:
  1. `build.gradle.kts`: `namespace = "com.halalgram.app"`, `applicationId = "com.halalgram.app"`; delete the line `id("com.google.gms.google-services")` (needed: the google-services plugin fails for the new id; Firebase Dart code keeps using explicit `firebase_options.dart` until P9).
  2. `settings.gradle.kts`: delete the line `id("com.google.gms.google-services") version "4.4.2" apply false`.
  3. `MainActivity.kt`:
     ```kotlin
     package com.halalgram.app

     import io.flutter.embedding.android.FlutterActivity

     class MainActivity : FlutterActivity()
     ```
  4. `rm -rf android/app/src/main/kotlin/com/example`
  5. `values/strings.xml`: `<?xml version="1.0" encoding="utf-8"?><resources><string name="app_name">Halalgram</string></resources>`; `values-ar/strings.xml`: same with `حلال كرام`.
  6. Manifest: `android:label="@string/app_name"`; add before `<application>`: `INTERNET`, `CAMERA`, `RECORD_AUDIO` `<uses-permission>` lines (keep existing media permissions).
- **Accept**: `grep -r "com.example" android/app/build.gradle.kts android/app/src/main` prints nothing; `grep google-services android/*.kts android/app/*.kts` prints nothing.
- **Verify**: `fvm flutter build apk --debug` succeeds (legacy app; no dart-defines needed). JDK missing → OWNER-ACTION per §1.3.
- **Commit**: `chore(android): P0-T05 rename app id to com.halalgram.app`

#### [ ] P0-T06 — Rename iOS app and add permissions
- **Read**: `ios/Runner/Info.plist`, `ios/Podfile` (first 3 lines). **Files**: M `ios/Runner.xcodeproj/project.pbxproj`, M `ios/Runner/Info.plist`, M `ios/Podfile`.
- **Steps**:
  1. `sed -i '' 's/com\.example\.instagramNew\.RunnerTests/com.halalgram.app.RunnerTests/g; s/com\.example\.instagramNew/com.halalgram.app/g' ios/Runner.xcodeproj/project.pbxproj`
  2. Info.plist: `CFBundleDisplayName` → `Halalgram`; `CFBundleName` → `halalgram`; add keys:
     - `NSPhotoLibraryUsageDescription` = `Halalgram uses your photos so you can share posts, stories and reels.`
     - `NSCameraUsageDescription` = `Halalgram uses the camera so you can capture photos and videos to share.`
     - `NSMicrophoneUsageDescription` = `Halalgram uses the microphone to record original audio for your videos.`
     - `PHPhotoLibraryPreventAutomaticLimitedAccessAlert` = `<true/>`
     - `CFBundleLocalizations` = array `ar`, `en`
  3. Podfile line 2: `platform :ios, '15.0'` (uncommented).
- **Accept**: `grep -c "com.halalgram.app" ios/Runner.xcodeproj/project.pbxproj` ≥ 3; `grep -c instagramNew ios/Runner.xcodeproj/project.pbxproj` = 0.
- **Verify**: `fvm flutter build ios --debug --no-codesign` (no Xcode → OWNER-ACTION). If CocoaPods reports a higher minimum iOS version, set exactly that version in the Podfile and log it.
- **Commit**: `chore(ios): P0-T06 rename bundle id and add usage descriptions`

#### [ ] P0-T07 — Lints: very_good_analysis + riverpod_lint, legacy excluded
- **Read**: `analysis_options.yaml`, `pubspec.yaml` (environment + dev_dependencies). **Files**: M `pubspec.yaml`, M `analysis_options.yaml` (full replace).
- **Steps**:
  1. pubspec `environment:` → `sdk: ^3.13.0` and `flutter: ">=3.47.0"`. dev_dependencies: remove `flutter_lints`, add `very_good_analysis: ^11.0.0`.
  2. Replace `analysis_options.yaml` with:
     ```yaml
     include: package:very_good_analysis/analysis_options.yaml

     analyzer:
       exclude:
         - "**/*.g.dart"
         - "**/*.freezed.dart"
         - build/**
         - android/**
         - ios/**
         - web/**
         - windows/**
         - macos/**
         - linux/**
         # LEGACY — delete each line in the task named in its comment
         - lib/main.dart                          # P1-T01
         - lib/firebase_options.dart              # P9-T09
         - lib/auth/**                            # P3-T12
         - lib/core/auth/**                       # P3-T12
         - test/user_profile_test.dart            # P3-T12
         - lib/util/**                            # P4-T14
         - lib/core/database/**                   # P4-T14
         - lib/core/config/supabase_config.dart   # P4-T14
         - lib/widgets/**                         # P6-T08
         - lib/screen/**                          # P7-T08
         - lib/data/**                            # P9-T09
       errors:
         invalid_annotation_target: ignore

     linter:
       rules:
         public_member_api_docs: false
         unnecessary_type_name_in_constructor: false
         sort_pub_dependencies: false

     plugins:
       riverpod_lint: 3.1.9
     ```
  3. `fvm flutter pub get`
- **Accept**: `fvm flutter analyze` → `No issues found!`.
- **Verify**: VERIFY-STD (skip l10n/build_runner/check_rules lines).
- **Commit**: `chore(lint): P0-T07 very_good_analysis and riverpod_lint`

#### [ ] P0-T08 — Folder skeleton, rule-check script, env template, launch config
- **Read**: none. **Files**: C `.gitkeep` files (below), C `tool/check_rules.sh`, C `env/example.json`, C `.vscode/launch.json`.
- **Steps**:
  1. Run:
     ```bash
     for d in config constants di errors l10n network pagination media router shell theme utils widgets; do mkdir -p lib/core/$d && touch lib/core/$d/.gitkeep; done
     for f in auth profile feed post comments story reel explore follow chat notifications moderation settings; do
       for s in data/datasources data/models data/repositories domain/entities domain/repositories domain/usecases di presentation/providers presentation/screens presentation/widgets; do
         mkdir -p lib/features/$f/$s && touch lib/features/$f/$s/.gitkeep; done; done
     for d in brand fonts translations; do mkdir -p assets/$d && touch assets/$d/.gitkeep; done
     mkdir -p test/helpers test/core test/features && touch test/helpers/.gitkeep
     ```
     (`lib/core/config` already has a legacy file; `.gitkeep` is harmless. Leave `.gitkeep` files forever.)
  2. `tool/check_rules.sh` (then `chmod +x tool/check_rules.sh`):
     ```bash
     #!/usr/bin/env bash
     # Halalgram static rule checks. Prints OK or the violations; exit 1 on violation.
     set -u
     shopt -s nullglob
     cd "$(dirname "$0")/.."
     fail=0
     scan() { # $1 description, $2 extended regex, $3.. paths
       local desc="$1" pattern="$2"; shift 2
       [ "$#" -eq 0 ] && return 0
       local out
       out=$(grep -rEn --include='*.dart' --exclude='*.g.dart' --exclude='*.freezed.dart' "$pattern" "$@" 2>/dev/null || true)
       if [ -n "$out" ]; then echo "VIOLATION: $desc"; echo "$out"; fail=1; fi
     }
     DOMAIN=(lib/features/*/domain)
     PRES=(lib/features/*/presentation)
     UI=(lib/features/*/presentation lib/core/widgets lib/core/shell)
     NO_SUPA=("${DOMAIN[@]}" "${PRES[@]}" lib/core/widgets lib/core/theme lib/core/router lib/core/shell lib/core/utils lib/core/media lib/core/errors lib/core/pagination)
     scan "supabase import outside data/di/core-network" "package:supabase_flutter" "${NO_SUPA[@]}"
     scan "flutter import in domain" "package:flutter/" "${DOMAIN[@]}"
     scan "data layer imported from presentation/domain" "import 'package:halalgram/features/[a-z_]+/data/" "${DOMAIN[@]}" "${PRES[@]}"
     scan "hardcoded Text string" "Text\(\s*['\"]" "${UI[@]}"
     scan "hardcoded color" "Color\(0x|Colors\.(red|green|blue|white|black|grey|amber|orange|purple|pink|yellow|teal|cyan|indigo|lime|brown|deepOrange|deepPurple|lightBlue|lightGreen|blueGrey)" "${UI[@]}"
     scan "numeric literal in EdgeInsets/Gap/SizedBox/radius/fontSize" "EdgeInsets[A-Za-z]*\.[a-zA-Z]+\([^)]*[0-9]|Gap\([0-9]|SizedBox\((width|height): [0-9]|BorderRadius\.circular\([0-9]|fontSize: [0-9]" "${UI[@]}"
     scan "non-directional layout" "EdgeInsets\.(only|fromLTRB)\(|Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)" "${UI[@]}"
     scan "print/debugPrint" "(^|[^a-zA-Z_])(print|debugPrint)\(" lib/core lib/features lib/app.dart lib/bootstrap.dart
     if [ -f assets/translations/ar.json ] && [ -f assets/translations/en.json ]; then
       python3 - <<'PY' || fail=1
     import json, sys
     def keys(d, p=""):
         out = set()
         for k, v in d.items():
             out |= keys(v, f"{p}{k}.") if isinstance(v, dict) else {f"{p}{k}"}
         return out
     ar = keys(json.load(open("assets/translations/ar.json", encoding="utf-8")))
     en = keys(json.load(open("assets/translations/en.json", encoding="utf-8")))
     if ar != en:
         print("VIOLATION: translation keys differ")
         print("missing in en:", sorted(ar - en)); print("missing in ar:", sorted(en - ar))
         sys.exit(1)
     PY
     fi
     [ "$fail" -eq 0 ] && echo "OK"
     exit "$fail"
     ```
  3. `env/example.json`: `{"SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co", "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_REPLACE_ME"}`
  4. `.vscode/launch.json`:
     ```json
     {"version": "0.2.0", "configurations": [
       {"name": "Halalgram (dev)", "request": "launch", "type": "dart", "program": "lib/main.dart",
        "toolArgs": ["--dart-define-from-file=env/dev.json"]}
     ]}
     ```
- **Accept**: `bash tool/check_rules.sh` prints `OK`; `lib/features/chat/presentation/widgets/.gitkeep` exists.
- **Verify**: VERIFY-STD (skip l10n/build_runner).
- **Commit**: `chore(repo): P0-T08 skeleton, rule checks, env template`

#### [ ] P0-T09 — OWNER-ACTION: cloud Supabase project + link + push 001–003
- **Read**: `supabase/migrations/003_storage_buckets.sql` (lines 50–60 only). **Files**: C `supabase/config.toml` (+ `supabase/.gitignore`) via CLI; possibly M `003_storage_buckets.sql` (one line, see step 4).
- **Steps**:
  1. OWNER-ACTION — ask the owner to: (a) create a Supabase cloud project; (b) export in the executor shell `SUPABASE_ACCESS_TOKEN` and `SUPABASE_DB_PASSWORD` (never in files); (c) give the project ref; (d) create `env/dev.json` from `env/example.json` with the real URL and publishable key; (e) Dashboard → Authentication → Providers → Email: enabled, "Confirm email" ON, minimum password length 8; (f) Authentication → Email Templates: "Confirm signup" and "Reset password" bodies contain `{{ .Token }}` (6-digit code shown to user); (g) Authentication → Settings: email OTP length 6, expiry 3600s.
  2. If `supabase/config.toml` is missing: `supabase init` (answer `N` to every prompt).
  3. `supabase link --project-ref <REF> -p "$SUPABASE_DB_PASSWORD"` then `supabase migration list`.
  4. If the Remote column is empty for 001–003 (never applied): delete exactly the line `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;` from `003_storage_buckets.sql` (Supabase forbids altering `storage.objects`; RLS is already on). This is the ONLY permitted edit to 001–003. If 001–003 are already remote: skip.
  5. `supabase db push --dry-run`, then `supabase db push`.
- **Accept**: `supabase migration list` shows 001, 002, 003 in both Local and Remote columns. `env/dev.json` exists and is ignored (`git status` does not list it).
- **Verify**: `supabase migration list`.
- **Commit**: `chore(db): P0-T09 link supabase cloud project`

**Phase 0 DoD**: see §8.

---

### Phase 1 — Foundation

#### [ ] P1-T01 — Approved packages, fonts, build.yaml, temporary main
- **Read**: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`. **Files**: M `pubspec.yaml` (dependencies, dev_dependencies, flutter sections), C `build.yaml` (§3.4), C `assets/fonts/Cairo-{Regular,SemiBold,Bold,ExtraBold}.ttf`, M `lib/main.dart` (temporary), M `analysis_options.yaml` (remove `lib/main.dart` exclude line), M `AndroidManifest.xml` (UCrop activity).
- **Steps**:
  1. Download fonts:
     ```bash
     cd assets/fonts
     curl -fsSL -o Cairo-Regular.ttf   "https://fonts.gstatic.com/s/cairo/v31/SLXgc1nY6HkvangtZmpQdkhzfH5lkSs2SgRjCAGMQ1z0hOA-W1Q.ttf"
     curl -fsSL -o Cairo-SemiBold.ttf  "https://fonts.gstatic.com/s/cairo/v31/SLXgc1nY6HkvangtZmpQdkhzfH5lkSs2SgRjCAGMQ1z0hD45W1Q.ttf"
     curl -fsSL -o Cairo-Bold.ttf      "https://fonts.gstatic.com/s/cairo/v31/SLXgc1nY6HkvangtZmpQdkhzfH5lkSs2SgRjCAGMQ1z0hAc5W1Q.ttf"
     curl -fsSL -o Cairo-ExtraBold.ttf "https://fonts.gstatic.com/s/cairo/v31/SLXgc1nY6HkvangtZmpQdkhzfH5lkSs2SgRjCAGMQ1z0hGA5W1Q.ttf"
     cd ../..
     ```
     If any URL 404s: `curl -s "https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800"` and use the new `src: url(...)` for each weight (Cairo is SIL OFL — bundling allowed).
  2. Replace pubspec `dependencies:` with the §5.1 list (alphabetical, exact versions) PLUS legacy entries kept for now: `cloud_firestore: ^5.0.0`, `cupertino_icons: ^1.0.8`, `date_format: ^2.0.7`, `firebase_auth: ^5.0.0`, `firebase_core: ^3.0.0`, `firebase_storage: ^12.0.0`, `flutter_screenutil: ^5.9.3`. Replace `dev_dependencies:` with §5.2.
  3. pubspec `flutter:` section:
     ```yaml
     flutter:
       uses-material-design: true
       assets:
         - images/
         - assets/brand/
         - assets/translations/
       fonts:
         - family: Cairo
           fonts:
             - asset: assets/fonts/Cairo-Regular.ttf
               weight: 400
             - asset: assets/fonts/Cairo-SemiBold.ttf
               weight: 600
             - asset: assets/fonts/Cairo-Bold.ttf
               weight: 700
             - asset: assets/fonts/Cairo-ExtraBold.ttf
               weight: 800
     ```
  4. Replace `lib/main.dart` (temporary until P1-T10; legacy code becomes unreachable):
     ```dart
     import 'package:flutter/material.dart';

     void main() => runApp(const MaterialApp(home: Scaffold()));
     ```
  5. Remove the `- lib/main.dart  # P1-T01` line from `analysis_options.yaml`.
  6. Manifest inside `<application>`: `<activity android:name="com.yalantis.ucrop.UCropActivity" android:screenOrientation="portrait" android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>` (if image_cropper 13 README on pub.dev states a different Android setup, follow the README and log it).
  7. `fvm flutter pub get`. If resolution fails ONLY because of a legacy package (firebase_*, cloud_firestore, date_format, flutter_screenutil), remove that legacy package (pre-approved) and log it in §10.
- **Accept**: `pub get` succeeds; 4 TTF files each > 100 KB (`ls -l assets/fonts`); analyze clean.
- **Verify**: VERIFY-STD (skip l10n line).
- **Commit**: `feat(core): P1-T01 approved packages, Cairo font, build config`

#### [ ] P1-T02 — Env config and constants
- **Read**: `lib/core/config/supabase_config.dart` (legacy, for values only). **Files**: C `lib/core/config/app_env.dart`, C `lib/core/constants/storage_buckets.dart`, C `lib/core/constants/media_limits.dart`, C `lib/core/constants/app_constants.dart`, C `lib/core/constants/prefs_keys.dart`, C `test/core/config/app_env_test.dart`.
- **Steps**:
  1. `AppEnv` (abstract final class): `supabaseUrl`, `supabasePublishableKey` via `String.fromEnvironment`; `static String? validationError()` returns null when both set, URL starts with `https://` and contains `.supabase.co`; else a short English reason (developer-facing only).
  2. `StorageBuckets`: `avatars`, `postImages = 'post-images'`, `reelVideos = 'reel-videos'`, `storyMedia = 'story-media'`, `chatMedia = 'chat-media'`.
  3. `MediaLimits`: `avatarMaxBytes 5MB`, `postImageMaxBytes 10MB`, `reelVideoMaxBytes 100MB`, `storyMaxBytes 50MB`, `chatImageMaxBytes 10MB`, `reelMaxDuration Duration(seconds: 90)`, `storyVideoMaxDuration Duration(seconds: 30)`, `imageMaxDimension 1440`, `avatarDimension 512`, `jpegQuality 82`, `maxCarouselItems 10`, `signedUrlTtlSeconds 3600`.
  4. `AppConstants`: `feedPageSize 10`, `gridPageSize 24`, `reelsPageSize 5`, `commentsPageSize 20`, `listPageSize 30`, `messagesPageSize 30`, `usernameMin 3`, `usernameMax 30`, `fullNameMax 60`, `bioMax 150`, `captionMax 2200`, `locationMax 100`, `commentMax 1000`, `messageMax 2000`, `highlightTitleMax 30`, `passwordMin 8`, `otpMinLength 6`, `otpMaxLength 8`, `recentSearchesMax 10`, `usernamePattern = r'^[a-z0-9_]{3,30}$'`.
  5. `PrefsKeys`: `themeMode = 'theme_mode'`, `guidelinesAccepted = 'guidelines_accepted_v1'`, `recentSearches = 'recent_searches'`, `bannerDismissedPrefix = 'banner_dismissed_'`, `reelsMuted = 'reels_muted'`.
  6. Test: `validationError()` returns non-null in tests (no defines).
- **Accept**: test passes; analyze clean.
- **Verify**: VERIFY-STD (skip l10n).
- **Commit**: `feat(core): P1-T02 env config and constants`

#### [ ] P1-T03 — Failure, Result, error mapping
- **Read**: §3.4 T1, T2. **Files**: C `lib/core/errors/failure.dart`, C `lib/core/errors/result.dart`, C `lib/core/network/error_mapper.dart`, C `lib/core/network/guard.dart`, C `test/core/network/error_mapper_test.dart`.
- **Steps**: write T1/T2 verbatim. Tests: `PostgrestException(message: 'duplicate key value violates unique constraint "profiles_username_key"', code: '23505')` → `UsernameTakenFailure`; code `42501` → `PermissionDeniedFailure`; `const SocketException('x')` → `NetworkFailure`; `AuthException('x', code: 'invalid_credentials')` → `InvalidCredentialsFailure`; `guard(() async => throw const SocketException('x'))` → `Left(NetworkFailure)`.
- **Accept**: 5 tests pass.
- **Verify**: VERIFY-STD (skip l10n).
- **Commit**: `feat(core): P1-T03 failure types and error mapping`

#### [ ] P1-T04 — Pagination, core providers, storage service
- **Read**: §3.4 T4, T10. **Files**: C `lib/core/pagination/{cursor,page_result,cursor_paging_controller}.dart`, C `lib/core/network/storage_service.dart`, C `lib/core/di/core_providers.dart`, C `test/core/pagination/page_result_test.dart`.
- **Steps**:
  1. T4 verbatim.
  2. `StorageService(SupabaseClient client)`: `String publicUrl(String bucket, String path)`; `String? publicUrlOrNull(String bucket, String? path)` (null/empty → null); `Future<String> signedUrl(String bucket, String path)` (TTL `MediaLimits.signedUrlTtlSeconds`); `Future<Map<String, String>> signedUrls(String bucket, List<String> paths)` (uses `createSignedUrls`, returns path → url); `Future<String> uploadFile({required String bucket, required String path, required File file})` (contentType from `lookupMimeType(file.path)`, `FileOptions(cacheControl: '31536000', upsert: false)`, returns `path`); `Future<void> remove(String bucket, List<String> paths)`.
  3. `core_providers.dart` (all `@Riverpod(keepAlive: true)`): `supabaseClient` → `Supabase.instance.client`; `sharedPreferences` → `throw UnimplementedError()` (overridden in bootstrap); `logger` → `Logger(printer: PrettyPrinter(methodCount: 0), level: kReleaseMode ? Level.warning : Level.debug)`; `storageService` → `StorageService(ref.watch(supabaseClientProvider))`.
  4. Test `PageResult.fromItems`: 10 items with pageSize 10 → `hasMore` true; 3 items → false.
- **Accept**: tests pass; generated `core_providers.g.dart` exists.
- **Verify**: VERIFY-STD (skip l10n).
- **Commit**: `feat(core): P1-T04 pagination, core providers, storage service`

#### [ ] P1-T05 — Theme tokens
- **Read**: §4.1, §4.2. **Files**: C `lib/core/theme/{app_colors,app_spacing,app_radii,app_sizes,app_durations,halal_colors}.dart`, C `lib/core/utils/context_ext.dart`.
- **Steps**:
  1. `AppColors` with two nested abstract final classes `AppColorsLight`/`AppColorsDark` (or `AppColors.lightPrimary`…) holding every §4.1 hex as `static const Color`.
  2. `AppSpacing`, `AppRadii` (+ `static const brXs..brXl, brPill` `BorderRadius.all(Radius.circular(..))`), `AppSizes`, `AppDurations` exactly §4.2.
  3. `HalalColors extends ThemeExtension<HalalColors>` fields: `gold, like, success, storyRing (List<Color>), seenRing, badge, onMedia, mediaScrim, skeleton`; `static const light`, `static const dark`; `copyWith`; `lerp` returns `t < 0.5 ? this : other`.
  4. `context_ext.dart`: `extension ThemeX on BuildContext { ColorScheme get colors; TextTheme get text; HalalColors get halal => Theme.of(this).extension<HalalColors>()!; bool get isRtl => Directionality.of(this) == TextDirection.rtl; }`.
- **Accept**: analyze clean; no other file changed.
- **Verify**: VERIFY-STD (skip l10n).
- **Commit**: `feat(theme): P1-T05 design tokens`

#### [ ] P1-T06 — Typography and ThemeData
- **Read**: §4.3, §4.1. **Files**: C `lib/core/theme/app_typography.dart`, C `lib/core/theme/app_theme.dart`, C `test/core/theme/app_theme_test.dart`.
- **Steps**:
  1. `AppTypography.textTheme(Color onSurface, Color onSurfaceVariant)` builds the §4.3 TextTheme (family `Cairo`, height 1.35; body/title colors `onSurface`, `bodySmall` `onSurfaceVariant`); `wordmark(Color)`, `statNumber(Color)`.
  2. `AppTheme.light()` / `AppTheme.dark()`: `useMaterial3: true`, explicit `ColorScheme(brightness, ...)` from §4.1, `fontFamily: 'Cairo'`, `scaffoldBackgroundColor: surface`, `splashFactory: NoSplash.splashFactory`, `highlightColor: Colors.transparent`; `appBarTheme` (toolbarHeight `AppSizes.appBarHeight`, elevation 0, scrolledUnderElevation 0, bg surface, fg onSurface, titleTextStyle titleMedium, centerTitle false); `dividerTheme` (outlineVariant, thickness 0.5, space 0.5); `inputDecorationTheme` (filled, fill surfaceContainerHighest, border `OutlineInputBorder(borderRadius: AppRadii.brSm, borderSide: BorderSide.none)`, contentPadding h `lg` v `md`); `filledButtonTheme`/`outlinedButtonTheme`/`textButtonTheme` (minimumSize height `buttonHeight`, shape radius `sm`, textStyle labelLarge); `bottomSheetTheme` (bg surfaceContainer, shape top radius `xl`); `snackBarTheme` (floating); `extensions: [HalalColors.light|dark]`.
  3. Test: `AppTheme.light().colorScheme.primary == const Color(0xFF0B5D3B)`; dark has `HalalColors` extension; `textTheme.bodyMedium!.fontSize == 14`.
- **Accept**: tests pass.
- **Verify**: VERIFY-STD (skip l10n).
- **Commit**: `feat(theme): P1-T06 typography and app theme`

#### [ ] P1-T07 — Theme mode controller
- **Read**: §3.4 T11. **Files**: C `lib/core/theme/theme_mode_controller.dart`, C `test/core/theme/theme_mode_controller_test.dart`.
- **Steps**: `@Riverpod(keepAlive: true) class ThemeModeController` — `ThemeMode build()` reads `PrefsKeys.themeMode` (`'light'|'dark'|'system'`, default system); `Future<void> setMode(ThemeMode mode)` writes and sets state. Test with `SharedPreferences.setMockInitialValues({'theme_mode': 'dark'})` + `ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])`.
- **Accept**: tests for read default, read dark, write light pass.
- **Verify**: VERIFY-STD (skip l10n).
- **Commit**: `feat(theme): P1-T07 persisted theme mode`

#### [ ] P1-T08 — Localization setup, base keys, formatters, Hijri, occasions
- **Read**: §2.1, §4.7. **Files**: C `assets/translations/ar.json`, C `assets/translations/en.json`, C `lib/core/l10n/l10n_setup.dart`, G `lib/core/l10n/locale_keys.g.dart`, C `lib/core/errors/failure_message.dart`, C `lib/core/utils/{formatters,hijri_date,occasions}.dart`, C `test/core/utils/{occasions_test,formatters_test}.dart`.
- **Steps**:
  1. `en.json`:
     ```json
     {
       "app": {"name": "Halalgram", "tagline": "Share what is good"},
       "common": {"ok": "OK", "cancel": "Cancel", "retry": "Try again", "save": "Save", "done": "Done", "next": "Next", "back": "Back", "delete": "Delete", "edit": "Edit", "close": "Close", "confirm": "Confirm", "share": "Share", "report": "Report", "block": "Block", "more": "More", "see_all": "See all", "loading": "Loading…", "coming_soon": "Coming soon", "hijri_suffix": "AH", "empty": "Nothing here yet"},
       "nav": {"home": "Home", "explore": "Explore", "create": "Create", "reels": "Reels", "profile": "Profile"},
       "create": {"title": "Create", "post": "Post", "story": "Story", "reel": "Reel"},
       "errors": {"network": "No internet connection. Please try again.", "unauthorized": "Your session has ended. Please log in again.", "invalid_credentials": "Incorrect email or password.", "email_not_confirmed": "Please confirm your email first.", "email_in_use": "This email is already registered.", "username_taken": "This username is taken.", "weak_password": "Please choose a stronger password.", "invalid_otp": "The code is invalid or expired.", "rate_limited": "Too many attempts. Please wait a moment.", "not_found": "Sorry, this content is unavailable.", "permission_denied": "Sorry, you don't have access to this.", "conflict": "This already exists.", "invalid_input": "Please check the entered information.", "storage": "Sorry, the upload failed. Please try again.", "server": "Sorry, something went wrong on our side.", "unknown": "Sorry, something went wrong."},
       "occasion": {"jumuah_title": "Jumu'ah Mubarak", "jumuah_subtitle": "Don't forget Surah Al-Kahf today", "ramadan_title": "Ramadan Kareem", "ramadan_subtitle": "May Allah accept your fasting", "eid_fitr_title": "Eid Mubarak", "eid_adha_title": "Eid al-Adha Mubarak", "eid_subtitle": "May Allah accept from us and you"}
     }
     ```
     `ar.json` same keys: app.name `حلال كرام`, tagline `شارك ما هو طيّب`; common: `حسنًا`, `إلغاء`, `حاول مجددًا`, `حفظ`, `تم`, `التالي`, `رجوع`, `حذف`, `تعديل`, `إغلاق`, `تأكيد`, `مشاركة`, `إبلاغ`, `حظر`, `المزيد`, `عرض الكل`, `جارٍ التحميل…`, `قريبًا`, `هـ`, `لا يوجد شيء بعد`; nav: `الرئيسية`, `استكشاف`, `إنشاء`, `المقاطع`, `الملف الشخصي`; create: `إنشاء`, `منشور`, `قصة`, `مقطع`; errors: `لا يوجد اتصال بالإنترنت، حاول مجددًا.`, `انتهت جلستك، يرجى تسجيل الدخول مجددًا.`, `البريد الإلكتروني أو كلمة المرور غير صحيحة.`, `يرجى تأكيد بريدك الإلكتروني أولًا.`, `هذا البريد مسجّل مسبقًا.`, `اسم المستخدم محجوز.`, `يرجى اختيار كلمة مرور أقوى.`, `الرمز غير صحيح أو منتهي الصلاحية.`, `محاولات كثيرة، يرجى الانتظار قليلًا.`, `عذرًا، هذا المحتوى غير متاح.`, `عذرًا، لا تملك صلاحية الوصول.`, `هذا موجود مسبقًا.`, `يرجى التحقق من المعلومات المدخلة.`, `عذرًا، فشل الرفع، حاول مجددًا.`, `عذرًا، حدث خطأ من جهتنا.`, `عذرًا، حدث خطأ ما.`; occasion: `جمعة مباركة`, `لا تنسَ قراءة سورة الكهف اليوم`, `رمضان كريم`, `تقبّل الله صيامكم`, `عيد فطر مبارك`, `عيد أضحى مبارك`, `تقبّل الله منا ومنكم`.
  2. `L10n` (abstract final class): `supportedLocales = [Locale('ar'), Locale('en')]`, `fallbackLocale = Locale('ar')`, `path = 'assets/translations'`; `static void registerTimeago()` → `timeago.setLocaleMessages('ar', timeago.ArMessages()); timeago.setLocaleMessages('en', timeago.EnMessages());`.
  3. Generate keys: `fvm dart run easy_localization:generate -S assets/translations -O lib/core/l10n -o locale_keys.g.dart -f keys`.
  4. `failure_message.dart` per §3.4 T3 (one `LocaleKeys.errors_*` per Failure variant; `ServerFailure` → `errors_server`).
  5. `formatters.dart`: `String formatCompact(int value, String languageCode)` (`NumberFormat.compact(locale: languageCode)`); `String formatRelative(DateTime date, String languageCode)` (`timeago.format(date, locale: languageCode)`); `String formatFullDate(DateTime date, String languageCode)` (`DateFormat.yMMMMd(languageCode)`); `String bidiSafe(String s) => '\u2068$s\u2069'`.
  6. `hijri_date.dart`: `String formatHijri(DateTime date, {required String languageCode, required String suffix})` → `HijriCalendar.setLocal(languageCode)`, `final h = HijriCalendar.fromDate(date)`, return `'${h.hDay} ${h.longMonthName} ${h.hYear} $suffix'`.
  7. `occasions.dart`: `enum Occasion { eidAlFitr, eidAlAdha, ramadan, jumuah }`; `Occasion? occasionFor(DateTime date)` priority: Shawwal (10) day 1–3 → eidAlFitr; Dhu al-Hijjah (12) day 10–13 → eidAlAdha; month 9 → ramadan; `date.weekday == DateTime.friday` → jumuah; else null. `extension OccasionL10n on Occasion { String get titleKey; String get subtitleKey; }`.
  8. Tests: build dates with `HijriCalendar().hijriToGregorian(1447, 9, 10)` → ramadan; `(1447, 10, 1)` → eidAlFitr; `(1447, 12, 10)` → eidAlAdha; `DateTime(2026, 10, 16)` → jumuah; `DateTime(2026, 10, 13)` → null. `formatCompact(1500, 'en')` == `'1.5K'`.
- **Accept**: tests pass; `check_rules.sh` OK (key parity).
- **Verify**: VERIFY-STD (full).
- **Commit**: `feat(l10n): P1-T08 translations, formatters, hijri, occasions`

#### [ ] P1-T09 — Routes, auth session, router with redirect
- **Read**: §3.4, route table below. **Files**: C `lib/core/router/app_routes.dart`, C `lib/core/network/auth_session.dart`, C `lib/core/router/app_router.dart`, C `lib/core/widgets/coming_soon_screen.dart`, C `test/core/router/redirect_test.dart`.
- **Route table** (paths/names fixed; "Screen" filled by the listed task; until then `ComingSoonScreen(titleKey: ...)`):

  | Const | Path | In shell | Screen (task) |
  |---|---|---|---|
  | login | `/login` | no | LoginScreen (P3-T03) |
  | signup | `/signup` | no | SignUpScreen (P3-T04) |
  | verifyEmail | `/verify-email` (query `email`) | no | VerifyEmailScreen (P3-T05) |
  | forgotPassword | `/forgot-password` | no | ForgotPasswordScreen (P3-T06) |
  | resetPassword | `/reset-password` (query `email`) | no | ResetPasswordScreen (P3-T06) |
  | home | `/home` | branch 0 | HomeScreen (P4-T08) |
  | explore | `/explore` | branch 1 | ExploreScreen (P7-T06) |
  | reels | `/reels` | branch 2 | ReelsScreen (P6-T03) |
  | myProfile | `/profile` | branch 3 | ProfileScreen(me) (P3-T10) |
  | search | `/search` | no | SearchScreen (P7-T07) |
  | userProfile | `/user/:userId` | no | ProfileScreen (P3-T10) |
  | connections | `/user/:userId/connections` (query `tab` = followers/following) | no | ConnectionsScreen (P7-T03) |
  | userReels | `/user/:userId/reels` (query `index`) | no | UserReelsScreen (P6-T07) |
  | postDetail | `/p/:postId` | no | PostDetailScreen (P4-T12) |
  | createPost | `/create/post` | no | CreatePostPickerScreen (P4-T04) |
  | createPostDetails | `/create/post/details` (extra `List<File>` + aspect) | no | CreatePostDetailsScreen (P4-T05) |
  | createStory | `/create/story` | no | CreateStoryScreen (P5-T03) |
  | createReel | `/create/reel` | no | CreateReelScreen (P6-T06) |
  | storyViewer | `/stories/:userId` | no | StoryViewerScreen (P5-T04) |
  | highlightViewer | `/highlight/:highlightId` | no | HighlightViewerScreen (P5-T06) |
  | highlightEditor | `/highlight-editor` (query `id` optional) | no | HighlightEditorScreen (P5-T07) |
  | inbox | `/inbox` | no | InboxScreen (P8-T02) |
  | chat | `/chat/:conversationId` | no | ChatScreen (P8-T03) |
  | notifications | `/notifications` | no | NotificationsScreen (P8-T07) |
  | followRequests | `/follow-requests` | no | FollowRequestsScreen (P7-T04) |
  | settings | `/settings` | no | SettingsScreen (P9-T05) |
  | editProfile | `/settings/edit-profile` | no | EditProfileScreen (P3-T11) |
  | blockedAccounts | `/settings/blocked` | no | BlockedAccountsScreen (P9-T03) |
  | guidelines | `/guidelines` | no | GuidelinesScreen (P9-T04) |
- **Steps**:
  1. `AppRoutes`: `static const login = '/login'; static const loginName = 'login';` … for every row; helpers `static String userProfilePath(String id) => '/user/$id';` (same for every parametrized route); `static const authPaths = {login, signup, verifyEmail, forgotPassword, resetPassword};`.
  2. `auth_session.dart`: `@Riverpod(keepAlive: true) class IsSignedIn extends _$IsSignedIn` — `bool build()`: subscribe `ref.watch(supabaseClientProvider).auth.onAuthStateChange` (store `StreamSubscription`, cancel in `ref.onDispose`), set `state = event.session != null`; initial `currentSession != null`. `@Riverpod(keepAlive: true) String? currentUserId(Ref ref) { ref.watch(isSignedInProvider); return ref.watch(supabaseClientProvider).auth.currentUser?.id; }`.
  3. Pure function in `app_router.dart`: `String? authRedirect({required bool signedIn, required String location})` → not signed in & path not in `authPaths` → `AppRoutes.login`; signed in & path in `authPaths` → `AppRoutes.home`; else null.
  4. `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)`: `rootNavigatorKey` global; `ValueNotifier<int>` refresh bumped by `ref.listen(isSignedInProvider, ...)`, disposed on `ref.onDispose`; `initialLocation: AppRoutes.home`; `redirect: (context, state) => authRedirect(signedIn: ref.read(isSignedInProvider), location: state.matchedLocation)`; `StatefulShellRoute.indexedStack` with 4 branches (home, explore, reels, myProfile) and `builder: (context, state, shell) => MainShell(navigationShell: shell)` (MainShell created in P1-T10 — in this task use a temporary `Scaffold(body: shell)` and replace in P1-T10); all non-shell routes `parentNavigatorKey: rootNavigatorKey`.
  5. `ComingSoonScreen({required String titleKey})`: `Scaffold(appBar: AppBar(title: Text(titleKey.tr())), body: EmptyView(...))` — EmptyView does not exist yet: use `Center(child: Text(LocaleKeys.common_coming_soon.tr()))`.
  6. Test `authRedirect` for 4 cases.
- **Accept**: tests pass.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(router): P1-T09 routes and auth redirect`

#### [ ] P1-T10 — Bootstrap, app widget, main shell, bottom nav, create sheet
- **Read**: `lib/core/router/app_router.dart`. **Files**: C `lib/bootstrap.dart`, C `lib/app.dart`, M `lib/main.dart`, C `lib/core/shell/{main_shell,halal_bottom_nav,create_sheet}.dart`, M `lib/core/router/app_router.dart` (use MainShell), M translations (keys `nav.*` exist; add `create.subtitle_post/story/reel` if used).
- **Steps**:
  1. `bootstrap.dart` `Future<void> bootstrap()`: `WidgetsFlutterBinding.ensureInitialized()`; if `AppEnv.validationError() != null` → `runApp(_ConfigErrorApp(message))` and return (the only allowed hardcoded text: `'Missing/invalid env/dev.json — إعدادات env/dev.json مفقودة أو غير صحيحة'` + message); `await EasyLocalization.ensureInitialized()`; `final prefs = await SharedPreferences.getInstance()`; `await Supabase.initialize(url: AppEnv.supabaseUrl, publishableKey: AppEnv.supabasePublishableKey)`; `L10n.registerTimeago()`; `runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: EasyLocalization(supportedLocales: L10n.supportedLocales, path: L10n.path, fallbackLocale: L10n.fallbackLocale, startLocale: L10n.fallbackLocale, useOnlyLangCode: true, child: const HalalgramApp())))`.
  2. `main.dart`: `Future<void> main() => bootstrap();`
  3. `app.dart` `HalalgramApp extends ConsumerWidget`: `MaterialApp.router(onGenerateTitle: (_) => LocaleKeys.app_name.tr(), debugShowCheckedModeBanner: false, theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: ref.watch(themeModeControllerProvider), locale: context.locale, supportedLocales: context.supportedLocales, localizationsDelegates: context.localizationDelegates, routerConfig: ref.watch(appRouterProvider))`.
  4. `HalalBottomNav({required int currentIndex, required ValueChanged<int> onTap, String? avatarUrl})`: 5 items per §4.4/§4.5 (visual indexes 0 home, 1 explore, 2 create, 3 reels, 4 profile); each wrapped in `Semantics(button: true, label: LocaleKeys.nav_*.tr())`.
  5. `MainShell({required StatefulNavigationShell navigationShell})`: visual index = branch index mapped (branch 0→0, 1→1, 2→3, 3→4); tap 2 → `showCreateSheet(context)`; others → `navigationShell.goBranch(branch, initialLocation: branch == navigationShell.currentIndex)`.
  6. `create_sheet.dart` `Future<void> showCreateSheet(BuildContext context)`: bottom sheet with title `create.title` and 3 `ListTile`s (icons `image`, `circlePlus`, `clapperboard`) pushing `AppRoutes.createPost/createStory/createReel`.
- **Accept**: app launches (with env) to `/login` ComingSoon; analyze clean.
- **Verify**: VERIFY-STD + `fvm flutter build apk --debug --dart-define-from-file=env/dev.json`.
- **Commit**: `feat(core): P1-T10 bootstrap, app shell, bottom nav`

#### [ ] P1-T11 — Core widgets A (media & identity)
- **Read**: §4.4–§4.6. **Files**: C `assets/brand/logo_mark.svg`, C `lib/core/widgets/{app_avatar,story_ring,app_network_image,halal_wordmark,directional_icon,heart_icon,bookmark_icon,badge_dot,count_text,max_width_box,hijri_date_text}.dart`.
- **Steps**:
  1. `logo_mark.svg`:
     ```xml
     <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
       <g fill="none" stroke="#B8964A" stroke-width="7" stroke-linejoin="round">
         <rect x="21" y="21" width="58" height="58"/>
         <rect x="21" y="21" width="58" height="58" transform="rotate(45 50 50)"/>
       </g>
       <circle cx="50" cy="50" r="10" fill="#B8964A"/>
     </svg>
     ```
  2. `AppNetworkImage({required String? url, BoxFit fit = BoxFit.cover, double? width, double? height})`: null url → `ColoredBox(skeleton)`; `CachedNetworkImage` with `memCacheWidth` computed from `LayoutBuilder` width × `MediaQuery.devicePixelRatioOf`; placeholder skeleton color box; error → centered `LucideIcons.imageOff`.
  3. `AppAvatar({required String? url, required double size})`: circle clip; null → `surfaceContainerHighest` circle with `LucideIcons.user` (size × 0.5).
  4. `StoryRing({required Widget child, required bool seen, required double avatarSize})`: outer = avatar + 2×(gap+ring); unseen → `SweepGradient(colors: halal.storyRing)`; seen → 1px `seenRing`; gap filled with `surface`.
  5. `HalalWordmark`: Row(SvgPicture.asset mark 22, Gap(xs), Text(app_name, style wordmark)).
  6. `DirectionalIcon(IconData icon, {double? size, Color? color})` → `Transform.flip(flipX: context.isRtl, child: Icon(...))`.
  7. `HeartIcon`, `BookmarkIcon` per §4.4; `BadgeDot` (8px badge circle); `CountBadge({required int count})` (min 18, pill, labelSmall, `99+` cap) inside `badge_dot.dart`; `CountText(int value, {TextStyle? style})` via `formatCompact(value, context.locale.languageCode)`; `MaxWidthBox(child)` centers with `AppSizes.maxContentWidth`; `HijriDateText(DateTime date)` → `'${formatFullDate} · ${formatHijri}'` in `bodySmall` secondary.
- **Accept**: analyze clean; check_rules OK.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(core): P1-T11 media and identity widgets`

#### [ ] P1-T12 — Core widgets B (inputs, states, dialogs)
- **Read**: §4.5–§4.6. **Files**: C `lib/core/widgets/{app_button,app_text_field,loading_view,error_view,empty_view,app_snackbar,confirm_dialog,app_bottom_sheet,skeletons}.dart`, M `lib/core/widgets/coming_soon_screen.dart` (use EmptyView), C `test/core/widgets/app_button_test.dart`, C `test/helpers/pump_app.dart` (§3.4 T17).
- **Steps**:
  1. `AppButton.primary/secondary/text({required String labelKey, required VoidCallback? onPressed, bool isLoading = false, bool expand = true})` — primary = `FilledButton`, secondary = `FilledButton.tonal` (bg surfaceContainerHighest), text = `TextButton`; loading → 18px `CircularProgressIndicator` + disabled.
  2. `AppTextField({required String labelKey, TextEditingController? controller, String? Function(String?)? validator, bool obscure = false, TextInputType? keyboardType, int? maxLength, int maxLines = 1, TextInputAction? action, ValueChanged<String>? onSubmitted, Widget? suffix, TextDirection? textDirection})` — label via `.tr()`; obscure shows eye toggle.
  3. `LoadingView` (centered adaptive indicator), `ErrorView({required Object error, VoidCallback? onRetry})` (icon `cloudOff`, `failureMessageKey(error).tr()`, retry button `common.retry`), `EmptyView({required IconData icon, required String messageKey, Widget? action})`.
  4. `showAppSnackBar(BuildContext context, String messageKey, {bool isError = false})`; `Future<bool> showConfirmDialog(BuildContext, {required String titleKey, required String messageKey, required String confirmKey, bool destructive = false})`; `Future<T?> showAppSheet<T>(BuildContext, {required WidgetBuilder builder, bool scrollControlled = true})` (adds handle 36×4).
  5. `skeletons.dart`: `PostCardSkeleton`, `ListTileSkeleton`, `GridSkeleton` using `Skeletonizer(enabled: true, child: <fake layout>)` with `skeleton` color.
  6. Widget test: AppButton loading shows `CircularProgressIndicator` and `onPressed` not called on tap.
- **Accept**: tests pass.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(core): P1-T12 input, state and dialog widgets`

#### [ ] P1-T13 — App icon and native splash
- **Read**: none. **Files**: C `assets/brand/app_icon.svg`, C `assets/brand/splash_logo.svg`, C `assets/brand/app_icon_1024.png`, C `assets/brand/splash_logo.png`, C `flutter_launcher_icons.yaml`, C `flutter_native_splash.yaml`, M generated Android/iOS icon & splash resources (allowed).
- **Steps**:
  1. `app_icon.svg`:
     ```xml
     <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
       <rect width="1024" height="1024" fill="#0B5D3B"/>
       <g fill="none" stroke="#D4B26A" stroke-width="56" stroke-linejoin="round">
         <rect x="286" y="286" width="452" height="452"/>
         <rect x="286" y="286" width="452" height="452" transform="rotate(45 512 512)"/>
       </g>
       <circle cx="512" cy="512" r="70" fill="#D4B26A"/>
     </svg>
     ```
     `splash_logo.svg`: same design, `viewBox="0 0 1152 1152" width="1152" height="1152"`, rects `x="376" y="376" width="400" height="400"` rotate `(45 576 576)`, stroke-width 48, circle `cx="576" cy="576" r="60"`.
  2. PNGs: `qlmanage -t -s 1024 -o assets/brand assets/brand/app_icon.svg && mv assets/brand/app_icon.svg.png assets/brand/app_icon_1024.png`; `qlmanage -t -s 1152 -o assets/brand assets/brand/splash_logo.svg && mv assets/brand/splash_logo.svg.png assets/brand/splash_logo.png`; check `sips -g pixelWidth -g pixelHeight` → exact sizes, else `sips -z <h> <w> <file>`.
  3. `flutter_launcher_icons.yaml`:
     ```yaml
     flutter_launcher_icons:
       android: true
       ios: true
       image_path: assets/brand/app_icon_1024.png
       remove_alpha_ios: true
       min_sdk_android: 21
     ```
     `flutter_native_splash.yaml`:
     ```yaml
     flutter_native_splash:
       color: "#0B5D3B"
       image: assets/brand/splash_logo.png
       android_12:
         color: "#0B5D3B"
         image: assets/brand/splash_logo.png
       android: true
       ios: true
       web: false
     ```
  4. `fvm dart run flutter_launcher_icons` then `fvm dart run flutter_native_splash:create`.
- **Accept**: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` updated (git diff shows binary change); iOS `AppIcon.appiconset` updated.
- **Verify**: VERIFY-STD + phase-end Android build.
- **Commit**: `feat(brand): P1-T13 app icon and splash`

#### [ ] P1-T14 — Shell widget test + Phase 1 DoD
- **Read**: `test/helpers/pump_app.dart`. **Files**: C `test/core/shell/halal_bottom_nav_test.dart`.
- **Steps**: test pumps `HalalBottomNav(currentIndex: 0, onTap: (i) => tapped = i)` with `pumpApp`; finds 5 `Semantics` buttons; tapping the 4th item reports index 3. Then run §8 Phase 1 DoD.
- **Accept**: test passes; DoD boxes ticked in §8.
- **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `test(core): P1-T14 bottom nav test and phase 1 DoD`

---

### Phase 2 — Database (cloud Supabase; app code unchanged, app stays runnable)
Common steps for P2-T01…T12 (referred to as **DB-STD**):
1. Write the migration file exactly per §6 (header comment, conventions §6.0).
2. `supabase db push --dry-run` → lists only the new file. Then `supabase db push`.
3. `supabase migration list` → new file present in Local and Remote.
4. `supabase db lint --linked --level error` → no errors for the new functions (if the command is unavailable in the installed CLI, log it and continue).
5. If push fails: read the error, fix the SQL in the SAME (not yet applied) file, retry once; second failure → STOP.
Verify for these tasks = DB-STD (no Flutter commands needed). Commit type `db`.

#### [ ] P2-T01 — 004 blocks & reports
- **Read**: §6.1 blocks/reports, §6.2 rows blocks/reports, §6.3 trg_block_cleanup. **Files**: C `supabase/migrations/004_moderation_blocks_reports.sql`.
- **Steps**: tables + indexes + RLS + policies; `on_block_cleanup()` function and `trg_block_cleanup`. (follow_requests does not exist yet → cleanup deletes follows only here; P2-T02 replaces the function with `CREATE OR REPLACE` to also delete follow_requests.)
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(moderation): P2-T01 blocks and reports tables`

#### [ ] P2-T02 — 005 profiles privacy, counters columns, follow_requests, signup trigger v2
- **Read**: §6.1 profiles/posts/reels/follow_requests, §6.3 handle_new_user v2, `supabase/migrations/001_initial_schema.sql` lines 193–264. **Files**: C `supabase/migrations/005_profiles_privacy_counters.sql`.
- **Steps**: ALTER TABLE profiles/posts/reels (columns + checks, `NOT VALID` where §6.1 says); column grants; `follow_requests` table + RLS + policies (§6.2; uses `is_private_user`/`is_blocked_between` → define those two helper functions HERE first, 006 must use `CREATE OR REPLACE` for them); `CREATE OR REPLACE FUNCTION public.handle_new_user()` v2 (reserved list from 001 + `'halalgram'`); `CREATE OR REPLACE FUNCTION public.on_block_cleanup()` also deleting follow_requests both ways.
- **Accept**: DB-STD green; in SQL editor `select column_name from information_schema.columns where table_name='profiles'` lists `is_private`, `full_name`, 4 counters (owner or MCP check, optional).
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(profile): P2-T02 privacy, counters columns, follow requests`

#### [ ] P2-T03 — 006 visibility helpers and policy rewrite
- **Read**: §6.2 fully. **Files**: C `supabase/migrations/006_visibility_helpers_policies.sql`.
- **Steps**: helper functions (`is_blocked_between`, `is_following`, `is_private_user`, `can_view_user`, `can_view_post`, `can_view_reel`) with grants; DROP the listed policies; CREATE the replacement policies for profiles, posts, reels, post_likes, reel_likes, post_comments, reel_comments, follows exactly per §6.2 table.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(core): P2-T03 visibility helpers and stricter policies`

#### [ ] P2-T04 — 007 post_media, saved_posts, comment replies & likes
- **Read**: §6.1 post_media/posts/post_comments/reel_comments/comment_likes/saved_posts, §6.2 rows. **Files**: C `supabase/migrations/007_post_media_saved_comments.sql`.
- **Steps**: create post_media (+RLS); `INSERT INTO public.post_media (post_id, user_id, position, storage_path) SELECT id, user_id, 0, image_path FROM public.posts WHERE image_path IS NOT NULL;` then `ALTER TABLE public.posts DROP COLUMN image_path;`; saved_posts (+RLS); post_comments new columns, check, indexes, `enforce_single_level_reply` trigger; reel_comments check + index; comment_likes (+RLS); column grants for post_comments/reel_comments.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(post): P2-T04 carousel media, saved posts, comment replies`

#### [ ] P2-T05 — 008 stories & highlights
- **Read**: §6.1 stories/story_views/highlights/highlight_items, §6.2 rows. **Files**: C `supabase/migrations/008_stories_highlights.sql`.
- **Steps**: create exactly these objects, columns from §6.1, policies from §6.2, nothing else:
  1. `stories` (id, user_id, media_path, media_type, duration_ms, created_at, expires_at) + indexes `(user_id, created_at DESC)` and `(expires_at)`.
  2. `story_views` PK `(story_id, viewer_id)` + index `(viewer_id)`.
  3. `highlights` (id, user_id, title, cover_story_id, created_at, updated_at) + `trigger_highlights_updated_at` BEFORE UPDATE calling `update_updated_at_column()` + index `(user_id, created_at)`.
  4. `highlight_items` PK `(highlight_id, story_id)` + index `(story_id)`.
  5. ENABLE RLS and the four §6.2 policy rows. `cover_story_id` is `ON DELETE SET NULL`.
- **Object list that must appear in the file**: stories, story_views, highlights, highlight_items, trigger_highlights_updated_at.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(story): P2-T05 stories and highlights tables`

#### [ ] P2-T06 — 009 chat
- **Read**: §6.1 conversations/conversation_members/messages, §6.2 rows, §6.3 trg_message_inserted. **Files**: C `supabase/migrations/009_chat.sql`.
- **Steps**: create exactly these objects from §6.1–§6.3, nothing else:
  1. `conversations` with `direct_key` UNIQUE and the last-message columns listed in §6.1.
  2. `conversation_members` PK `(conversation_id, user_id)`.
  3. `messages` with the kind CHECK from §6.1 and index `(conversation_id, created_at DESC, id DESC)`.
  4. `is_conversation_member(p_conversation_id uuid)` STABLE SECURITY DEFINER: EXISTS member row with `user_id = auth.uid()`. Grants per §6.0.
  5. `on_message_inserted` + `trg_message_inserted` AFTER INSERT: update conversation summary and the sender's `last_read_at`.
  6. ENABLE RLS. INSERT on conversations and conversation_members is none (RPC). No typing-indicator column, no group chat, no message-request table.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(chat): P2-T06 conversations and messages`

#### [ ] P2-T07 — 010 notifications
- **Read**: §6.1 notifications, §6.2 row, §6.3 notifications table. **Files**: C `supabase/migrations/010_notifications.sql`.
- **Steps**: table, indexes, grants, RLS + policies; `create_notification(...)` SECURITY DEFINER (not granted to authenticated — internal only: `REVOKE ALL ... FROM PUBLIC, anon, authenticated`); one trigger function per row of the §6.3 notifications table; DELETE triggers remove matching rows.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(notifications): P2-T07 notifications and triggers`

#### [ ] P2-T08 — 011 counters
- **Read**: §6.3 counters. **Files**: C `supabase/migrations/011_counters.sql`.
- **Steps**: copy the `count_post_likes` pattern in §6.3 once per pair below. Decrement uses `GREATEST(x - 1, 0)`. Then one backfill `UPDATE` per counter.
  - `post_likes` INS/DEL → `posts.likes_count`
  - `post_comments` INS/DEL → `posts.comments_count`; when `parent_id` is not null also parent `replies_count`
  - `comment_likes` INS/DEL → `post_comments.likes_count`
  - `reel_likes` INS/DEL → `reels.likes_count`
  - `reel_comments` INS/DEL → `reels.comments_count`
  - `follows` INS/DEL → `profiles.following_count` of follower and `followers_count` of following
  - `posts` INS/DEL → `profiles.posts_count`
  - `reels` INS/DEL → `profiles.reels_count`
  Do not add counters for stories, messages, or blocks.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(core): P2-T08 counter triggers and backfill`

#### [ ] P2-T09 — 012 storage v2
- **Read**: §6.5, `supabase/migrations/003_storage_buckets.sql` (policy pattern). **Files**: C `supabase/migrations/012_storage_v2.sql`.
- **Steps**: insert buckets `story-media`, `chat-media` (ON CONFLICT DO UPDATE like 003); `UPDATE storage.buckets SET allowed_mime_types = ARRAY['video/mp4','video/quicktime','image/jpeg'] WHERE id = 'reel-videos';`; policies per §6.5 (names `story_media_public_read`, `story_media_insert_own`, `story_media_update_own`, `story_media_delete_own`, `chat_media_member_read`, `chat_media_insert_member`, `chat_media_delete_own`). Do NOT `ALTER TABLE storage.objects`.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(storage): P2-T09 story and chat buckets`

#### [ ] P2-T10 — 013 read RPCs
- **Read**: §6.4 rows marked 013, reference SQL. **Files**: C `supabase/migrations/013_rpc_read.sql`.
- **Steps**: implement exactly these 013 functions. Copy argument names, return columns, and security from the §6.4 row. Copy the `get_home_feed` SQL block and change only the WHERE/JOIN the row's semantics require. Grants per §6.0. `is_username_available` is also granted to `anon`. No extra functions.
  Object list: `is_username_available`, `get_profile`, `search_profiles`, `get_home_feed`, `get_post`, `get_explore_posts`, `get_user_posts`, `get_saved_posts`, `get_reels_feed`, `get_user_reels`.
- **Accept**: DB-STD green; optional SQL-editor check: `select * from get_home_feed();` as authenticated returns 0+ rows without error.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(core): P2-T10 read RPCs`

#### [ ] P2-T11 — 014 social RPCs
- **Read**: §6.4 rows marked 014. **Files**: C `supabase/migrations/014_rpc_social.sql`.
- **Steps**: implement exactly these 014 functions from §6.4. `accept_follow_request` calls `create_notification` with type `follow_accept` (allowed: SECURITY DEFINER). RAISE only the codes in §6.0 (`blocked`, `not_found`, `private`, `invalid`). No extra functions.
  Object list: `create_post`, `follow_user`, `unfollow_user`, `accept_follow_request`, `decline_follow_request`, `remove_follower`, `get_followers`, `get_following`, `get_follow_requests`, `get_post_comments`, `get_comment_replies`, `get_reel_comments`, `get_stories_tray`, `get_user_stories`, `mark_story_viewed`, `get_story_viewers`, `get_my_story_archive`, `get_user_highlights`, `get_highlight_stories`, `save_highlight`.
- **Accept**: DB-STD green.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(core): P2-T11 social RPCs`

#### [ ] P2-T12 — 015 chat/notification RPCs + 016 realtime
- **Read**: §6.4 rows marked 015, §6.6. **Files**: C `supabase/migrations/015_rpc_chat_notifications.sql`, C `supabase/migrations/016_realtime.sql`.
- **Steps**: 015 implements exactly: `get_or_create_direct_conversation`, `get_conversations`, `get_messages`, `mark_conversation_read`, `get_notifications`, `mark_notifications_read`, `get_unread_counts`. 016 is only:
  `ALTER PUBLICATION supabase_realtime ADD TABLE public.messages, public.notifications;`
  Do not add conversations or profiles to the publication.
- **Accept**: DB-STD green for both files.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `db(chat): P2-T12 chat and notification RPCs, realtime`

#### [ ] P2-T13 — RLS smoke test + docs addendum
- **Read**: §6.2, §6.4. **Files**: C `supabase/tests/rls_smoke.sql`, M `SCHEMA_DESIGN_DECISIONS.md` (append section "## 16. Halalgram v1 additions (migrations 004–016)").
- **Steps**:
  1. `rls_smoke.sql` = one transaction `BEGIN; … ROLLBACK;`: insert 3 users into `auth.users (id, email, raw_user_meta_data)` with fixed UUIDs A/B/C and usernames `smoke_a/b/c`; switch identity with `SET LOCAL ROLE authenticated; SELECT set_config('request.jwt.claims', json_build_object('sub', '<uuid>', 'role', 'authenticated')::text, true);`; `DO $$ BEGIN ASSERT <cond>, '<label>'; END $$;` checks: (1) A sets `is_private = true`; A inserts a post; (2) as B: `select count(*) from posts where user_id = A` = 0; (3) as B: `follow_user(A)` = `'requested'`; (4) as A: `accept_follow_request(B)`; (5) as B: post visible (=1) and `profiles.followers_count` of A = 1; (6) as B: like A's post → as A: 1 `post_like` notification; posts.likes_count = 1; (7) as A: block C → as C: `select count(*) from profiles where id = A` = 0; (8) as C: `follow_user(A)` raises; (9) as B: `get_or_create_direct_conversation(A)` returns uuid; insert message; as C: `select count(*) from messages` = 0.
  2. OWNER-ACTION (or MCP `execute_sql` if owner approved): run the file in the SQL editor; all asserts pass (no error). If inserting into `auth.users` is rejected, owner creates 3 test users in Dashboard and the script uses their UUIDs.
  3. Addendum: bullet list of new tables, privacy model (`can_view_user`), counters, notifications, buckets, realtime, and the 003 one-line fix if applied.
- **Accept**: owner confirms "all asserts passed"; Supabase Dashboard → Advisors → Security shows no "RLS disabled" errors for public tables.
- **Verify**: DB-STD (the 5 steps under the Phase 2 heading). No Flutter commands.
- **Commit**: `test(db): P2-T13 RLS smoke test and schema addendum`

#### [ ] P2-T14 — QA seed script (not applied automatically)
- **Read**: §6.1 posts/post_media/follows, §8.1 setup line. **Files**: C `supabase/seed/qa_seed.sql`.
- **Steps**: the file starts with three placeholders the owner replaces after creating users in Dashboard → Authentication (emails `qa-a@halalgram.test`, `qa-b@halalgram.test`, `qa-c@halalgram.test`; A private, B and C public):
  ```sql
  -- Replace before running. Do not commit real UUIDs.
  -- \set qa_a '...' \set qa_b '...' \set qa_c '...'
  ```
  Then, inside `BEGIN; … COMMIT;`, using those UUIDs only if the matching `profiles` rows already exist (`INSERT … SELECT` guarded by `WHERE EXISTS`): set A's `is_private = true`; insert 25 posts for B (caption `seed-b-NN`, one `post_media` row each, position 0, storage_path left as a placeholder the owner may ignore); insert follow B→A only when A is public is NOT done — instead insert a `follow_requests` row C→A and a `follows` row B→C. No `auth.users` inserts. Header comment: "Run by the owner in the SQL editor after the three QA users exist. Not part of `supabase db push`."
- **Accept**: file exists; `grep -n "auth.users" supabase/seed/qa_seed.sql` prints nothing; `grep -c "seed-b-" supabase/seed/qa_seed.sql` ≥ 25.
- **Verify**: the two greps. Do not execute the script.
- **Commit**: `test(db): P2-T14 QA seed script`

---

### Phase 3 — Auth & profile

#### [ ] P3-T01 — Auth domain + validators
- **Read**: §3.4 T5, T8, T9. **Files**: C `lib/core/utils/validators.dart`, C `lib/features/auth/domain/entities/{auth_user,sign_up_result}.dart`, C `lib/features/auth/domain/repositories/auth_repository.dart`, C `lib/features/auth/domain/usecases/{sign_in,sign_up,verify_email_otp,resend_signup_otp,send_password_reset,reset_password_with_otp,sign_out,check_username_available}.dart`, C `test/core/utils/validators_test.dart`, C `test/features/auth/domain/sign_up_test.dart`, M translations (`validation.*`).
- **Steps**:
  1. `Validators` (static, return l10n key or null): `email` (non-empty, `^[^@\s]+@[^@\s]+\.[^@\s]+$`), `password` (≥ `AppConstants.passwordMin`), `username` (lowercased trimmed matches `AppConstants.usernamePattern`), `fullName` (≤ 60), `bio` (≤ 150), `otp` (digits only, length 6–8), `required`. Keys: `validation.email_invalid` "Please enter a valid email.", `validation.password_short` "Password must be at least 8 characters.", `validation.username_invalid` "Use 3–30 lowercase letters, numbers or _.", `validation.too_long` "This text is too long.", `validation.otp_invalid` "Enter the code from your email.", `validation.required` "This field is required.", `validation.passwords_mismatch` "Passwords do not match." (+ Arabic).
  2. `AuthUser(id, email)`; `enum SignUpResult { signedIn, needsEmailConfirmation }`.
  3. `AuthRepository`: `signIn({email,password}) → Unit`, `signUp({email,password,username,fullName}) → SignUpResult`, `verifyEmailOtp({email,token}) → Unit`, `resendSignupOtp(email)`, `sendPasswordReset(email)`, `resetPasswordWithOtp({email,token,newPassword})`, `signOut()`, `isUsernameAvailable(username) → bool`.
  4. Use cases: validate inputs first (`left(Failure.validation(messageKey: ...))`) then delegate; `SignUp` lowercases/trims username and email.
  5. Tests: validators table-driven; `SignUp` with invalid username returns validation failure and never calls repository (`verifyNever`).
- **Accept**: tests pass.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(auth): P3-T01 auth domain and validators`

#### [ ] P3-T02 — Auth data + DI
- **Read**: §3.4 T7, T8, T10. **Files**: C `lib/features/auth/data/datasources/auth_remote_data_source.dart`, C `lib/features/auth/data/repositories/auth_repository_impl.dart`, C `lib/features/auth/di/auth_providers.dart`.
- **Steps**: datasource methods: `signInWithPassword`; `signUp(email, password, data: {'username': u, 'full_name': n})` → `res.session == null ? needsEmailConfirmation : signedIn`; `verifyOTP(email:, token:, type: OtpType.email)`; `resend(type: OtpType.signup, email:)`; `resetPasswordForEmail(email)` (no redirectTo); reset = `verifyOTP(type: OtpType.recovery)` then `updateUser(UserAttributes(password: newPassword))`; `signOut()`; `rpc<bool>('is_username_available', params: {'p_username': u})`. Repository wraps each with `guard`. DI providers for datasource, repository, all 8 use cases.
- **Accept**: analyze clean; check_rules OK.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(auth): P3-T02 auth data layer`

#### [ ] P3-T03 — Login screen
- **Read**: §4.5, §3.4 T11. **Files**: C `lib/features/auth/presentation/providers/login_controller.dart`, C `lib/features/auth/presentation/screens/login_screen.dart`, C `lib/features/auth/presentation/widgets/auth_scaffold.dart`, M `lib/core/router/app_router.dart` (login route), M translations (`auth.login.*`).
- **Steps**:
  1. `AuthScaffold({required List<Widget> children})`: SafeArea + `MaxWidthBox` + scrollable column, padding `xxl`, wordmark at top (mark 48 + wordmark), `keyboardDismissBehavior: onDrag`.
  2. `LoginController` (AsyncNotifier<void>, `build()` returns null): `Future<Failure?> submit(email, password)`.
  3. Screen: Form with email + password `AppTextField`s, end-aligned text button "Forgot password?", primary "Log in" (loading while submitting), divider, row "Don't have an account?" + "Sign up" → `context.push(AppRoutes.signup)`. On `EmailNotConfirmedFailure` → `context.push('${AppRoutes.verifyEmail}?email=$email')`; other failures → snackbar. Success → nothing (router redirects).
  4. Keys `auth.login.title` "Welcome back", `email` "Email", `password` "Password", `forgot` "Forgot password?", `submit` "Log in", `no_account` "Don't have an account?", `sign_up` "Sign up".
- **Accept**: unauthenticated launch shows login; wrong password shows `errors.invalid_credentials` snackbar (manual QA).
- **Verify**: VERIFY-STD.
- **Commit**: `feat(auth): P3-T03 login screen`

#### [ ] P3-T04 — Sign-up screen with username availability
- **Read**: P3-T03 files. **Files**: C `lib/features/auth/presentation/providers/{sign_up_controller,username_availability_controller}.dart`, C `lib/features/auth/presentation/screens/sign_up_screen.dart`, C `lib/core/utils/debouncer.dart`, M `app_router.dart`, M translations (`auth.signup.*`).
- **Steps**:
  1. `Debouncer({required Duration delay})` with `run(VoidCallback)` and `dispose()`.
  2. `UsernameAvailabilityController` family(username) → `Future<bool>`; screen debounces `AppDurations.debounce` before watching; suffix icon: checking spinner / `check` in success / `x` in error.
  3. Fields: email, full name, username (`FilteringTextInputFormatter.allow(RegExp('[a-z0-9_]'))` + lowercase), password. Note under form: "By signing up you agree to our content guidelines" with link → `AppRoutes.guidelines`.
  4. Submit → `SignUpResult.needsEmailConfirmation` → `context.go('${AppRoutes.verifyEmail}?email=...')`; `signedIn` → router redirects.
  5. Keys: `auth.signup.title` "Create your account", `full_name` "Full name", `username` "Username", `submit` "Sign up", `have_account` "Already have an account?", `log_in` "Log in", `agree` "By signing up you agree to our", `guidelines_link` "content guidelines".
- **Accept**: taken username shows `x`; submit creates user; DB `profiles.username` equals chosen username (manual QA).
- **Verify**: VERIFY-STD.
- **Commit**: `feat(auth): P3-T04 sign up with username check`

#### [ ] P3-T05 — Verify email (OTP) screen
- **Read**: P3-T03 files. **Files**: C `lib/features/auth/presentation/providers/verify_email_controller.dart`, C `lib/features/auth/presentation/screens/verify_email_screen.dart`, M `app_router.dart`, M translations (`auth.verify.*`).
- **Steps**: shows "We sent a code to {email}" (`bidiSafe`); code field (numeric, `autofillHints: [AutofillHints.oneTimeCode]`, max 8); Verify button; "Resend code" with 60-second countdown (`Timer.periodic`, disposed); back to login. Success → router redirects to home.
- Keys: `title` "Confirm your email", `sent_to` "We sent a code to {email}", `code` "Code", `submit` "Confirm", `resend` "Resend code", `resend_in` "Resend in {seconds}s", `resent` "A new code was sent.".
- **Accept**: valid code signs in (manual QA).
- **Verify**: VERIFY-STD.
- **Commit**: `feat(auth): P3-T05 email verification`

#### [ ] P3-T06 — Forgot / reset password (OTP)
- **Read**: P3-T05 files. **Files**: C `lib/features/auth/presentation/providers/password_reset_controller.dart`, C `lib/features/auth/presentation/screens/{forgot_password_screen,reset_password_screen}.dart`, M `app_router.dart`, M translations (`auth.forgot.*`, `auth.reset.*`).
- **Steps**: Forgot: email → `sendPasswordReset` → push `resetPassword?email=`. Reset: code + new password + confirm (must match) → `resetPasswordWithOtp` → snackbar `auth.reset.done` → router redirects (session created).
- Keys: forgot `title` "Reset your password", `subtitle` "Enter your email and we'll send you a code.", `submit` "Send code"; reset `title` "Choose a new password", `new_password` "New password", `confirm_password` "Confirm password", `submit` "Save password", `done` "Your password was changed.".
- **Accept**: manual QA end-to-end.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(auth): P3-T06 password reset via code`

#### [ ] P3-T07 — Auth widget tests
- **Read**: `test/helpers/pump_app.dart`. **Files**: C `test/features/auth/presentation/login_screen_test.dart`.
- **Steps**: override `signInProvider` with a mock; tap submit with empty fields → shows `validation.email_invalid` text (EN locale); valid input calls use case once.
- **Accept**: tests pass.
- **Verify**: VERIFY-STD.
- **Commit**: `test(auth): P3-T07 login screen tests`

#### [ ] P3-T08 — Media utilities (picker, cropper, compressor)
- **Read**: §5 rows wechat_assets_picker, image_cropper, image_picker, flutter_image_compress. **Files**: C `lib/core/media/{media_picker,image_compressor}.dart`, M translations (`media.*`).
- **Steps**:
  1. `ImageCompressor.compress(File file, {int maxDimension = MediaLimits.imageMaxDimension, int quality = MediaLimits.jpegQuality}) → Future<File>`: `FlutterImageCompress.compressAndGetFile(file.path, '<tempDir>/<uuid>.jpg', minWidth: maxDimension, minHeight: maxDimension, quality: quality, format: CompressFormat.jpeg)`; null → throw `Failure.storage()`.
  2. `MediaPicker` (static, needs `BuildContext`): `pickImages(context, {required int max})` → `AssetPicker.pickAssets(context, pickerConfig: AssetPickerConfig(maxAssets: max, requestType: RequestType.image, textDelegate: assetPickerTextDelegateFromLocale(context.locale)))` → files via `asset.file`; `pickVideo(context)` (RequestType.video, max 1); `pickImageOrVideo(context)` (RequestType.common, max 1) returning `(File, bool isVideo)`; `captureImage()` / `captureVideo({Duration? maxDuration})` via `ImagePicker`; `cropImage(BuildContext, File, {required CropAspect aspect})` where `enum CropAspect { square, portrait45, circle }` → `ImageCropper().cropImage(sourcePath:, aspectRatio: CropAspectRatio(ratioX:, ratioY:), uiSettings: [AndroidUiSettings(toolbarTitle: LocaleKeys.media_crop_title.tr(), toolbarColor: context.colors.surface, toolbarWidgetColor: context.colors.onSurface, activeControlsWidgetColor: context.colors.primary, lockAspectRatio: true, cropStyle: aspect == circle ? CropStyle.circle : CropStyle.rectangle), IOSUiSettings(title: ..., aspectRatioLockEnabled: true, cropStyle: ...)])`.
  3. Permission denied (picker returns null because of `PermissionState.denied`) → `showAppSnackBar(media.permission_denied)` with action opening `openAppSettings()` (add optional `actionKey`/`onAction` params to `showAppSnackBar` in this task — listed file M `lib/core/widgets/app_snackbar.dart`).
  4. Keys: `media.crop_title` "Crop", `media.permission_denied` "Please allow access in Settings.", `media.open_settings` "Open Settings".
  If any named API differs in the installed version → STOP (do not guess).
- **Accept**: analyze clean.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(core): P3-T08 media picker, cropper, compressor`

#### [ ] P3-T09 — Profile domain + data + DI
- **Read**: §3.4 T5–T10, §6.4 get_profile. **Files**: C `lib/features/profile/domain/entities/{user_summary,profile}.dart`, C `lib/features/profile/domain/repositories/profile_repository.dart`, C `lib/features/profile/domain/usecases/{get_profile,update_profile,upload_avatar,remove_avatar,set_account_privacy}.dart`, C `lib/features/profile/data/models/profile_model.dart`, C `lib/features/profile/data/datasources/profile_remote_data_source.dart`, C `lib/features/profile/data/repositories/profile_repository_impl.dart`, C `lib/features/profile/di/profile_providers.dart`, C `test/features/profile/data/profile_model_test.dart`.
- **Steps**:
  1. `UserSummary(id, username, fullName, avatarUrl?)`; `Profile` = all `get_profile` columns in camelCase, `avatarUrl` instead of path.
  2. Repo: `getProfile(userId)`, `updateProfile({fullName, username, bio})`, `uploadAvatar(String filePath)` (compress to `MediaLimits.avatarDimension`, upload `avatars/{uid}/{uuid}.jpg`, update `avatar_path`, then best-effort remove previous path), `removeAvatar()`, `setAccountPrivacy({required bool isPrivate})`.
  3. Datasource uses `rpc('get_profile')` (0 rows → throw `Failure.notFound()`), `from('profiles').update(...)`.
  4. Test: `ProfileModel.fromJson(<sample map>)` → `toEntity` maps counts and builds avatar URL via a fake `StorageService` (mocktail).
- **Accept**: tests pass.
- **Verify**: VERIFY-STD.
- **Commit**: `feat(profile): P3-T09 profile domain and data`

#### [ ] P3-T10 — Profile screen (own + others)
- **Read**: §4.5 Profile, §3.4 T11/T13. **Files**: C `lib/features/profile/presentation/providers/profile_controller.dart`, C `lib/features/profile/presentation/screens/profile_screen.dart`, C `lib/features/profile/presentation/widgets/{profile_header,profile_stats,profile_actions,profile_tabs,private_account_view,profile_menu_sheet}.dart`, M `app_router.dart` (myProfile + userProfile routes), M `lib/core/shell/main_shell.dart` (profile avatar in nav), M translations (`profile.*`).
- **Steps**:
  1. `ProfileScreen({String? userId})` — null = me (`currentUserIdProvider`). App bar: username (`titleMedium`, lock icon if private); own: `menu` icon → `ProfileMenuSheet` (items: Settings → `AppRoutes.settings`; Log out → confirm → `SignOut`); other: `ellipsis` (empty sheet placeholder until P9-T02 — show nothing: hide the icon until P9).
  2. `NestedScrollView` header = `ProfileHeader` (avatar 86 with StoryRing if `hasActiveStory`; stats posts/followers/following → followers/following tap → `AppRoutes.connectionsPath(id, tab)`), name, bio, `ProfileActions` (own: Edit profile → `AppRoutes.editProfile`, Share profile → share_plus text `profile.share_text`; other: disabled Follow placeholder + disabled Message placeholder; replaced in P7-T02/P8-T02), then `ProfileTabs` (grid/reels/saved own) with `ComingSoon`-style `EmptyView` bodies (replaced P4-T13/P6-T07).
  3. `!canView` → `PrivateAccountView` instead of tabs.
  4. Keys: `profile.posts` "Posts", `followers` "Followers", `following` "Following", `edit` "Edit profile", `share` "Share profile", `share_text` "Follow @{username} on Halalgram", `follow` "Follow", `message` "Message", `private_title` "This account is private", `private_subtitle` "Follow this account to see their posts and reels.", `menu_settings` "Settings", `menu_logout` "Log out", `logout_confirm` "Do you want to log out?".
- **Accept**: own profile shows real counts; another user's private profile shows lock view (manual QA with 2 accounts).
- **Verify**: VERIFY-STD + phase builds optional.
- **Commit**: `feat(profile): P3-T10 profile screen`

#### [ ] P3-T11 — Edit profile (avatar, fields, privacy)
- **Read**: P3-T10 files. **Files**: C `lib/features/profile/presentation/providers/edit_profile_controller.dart`, C `lib/features/profile/presentation/screens/edit_profile_screen.dart`, C `lib/features/profile/presentation/widgets/avatar_picker_sheet.dart`, M `app_router.dart`, M translations (`profile.edit.*`).
- **Steps**: app bar: close (start), title, Save text button (end, loading). Avatar 86 centered + "Change photo" → sheet: Choose from library (pickImages max 1 → crop circle → upload), Take photo (capture → crop → upload), Remove photo (if has avatar). Fields: full name, username (formatter + availability check unless unchanged), bio (maxLength 150, counter). `SwitchListTile` Private account + helper text. Save → `UpdateProfile` (+ `SetAccountPrivacy` if changed) → `ref.invalidate(profileControllerProvider)` → pop + snackbar.
- Keys: `title` "Edit profile", `change_photo` "Change photo", `from_library` "Choose from library", `take_photo` "Take photo", `remove_photo` "Remove photo", `bio` "Bio", `private` "Private account", `private_help` "Only approved followers can see your posts, reels and stories.", `saved` "Profile updated.".
- **Accept**: avatar upload visible on profile after save (manual QA).
- **Verify**: VERIFY-STD.
- **Commit**: `feat(profile): P3-T11 edit profile and avatar upload`

#### [ ] P3-T12 — Remove legacy auth/profile + Phase 3 DoD
- **Read**: legacy inventory (top of §7). **Files**: D the P3-T12 row of the legacy inventory; M `analysis_options.yaml` (remove lines for `lib/auth/**`, `lib/core/auth/**`, `test/user_profile_test.dart`).
- **Steps**: `git rm` each listed file; VERIFY-STD; run Phase 3 DoD.
- **Accept**: `ls lib/auth lib/core/auth 2>/dev/null` prints nothing; tests pass.
- **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `chore(auth): P3-T12 remove legacy auth and profile code`

---

### Phase 4 — Posts, feed, comments

#### [ ] P4-T01 — Post domain
- **Read**: §3.4 T5, T8, T9, T12. **Files**: C `lib/features/post/domain/entities/{post_media,post,post_interaction,grid_item,new_post_image,create_post_input}.dart`, C `lib/features/post/domain/repositories/post_repository.dart`, C `lib/features/post/domain/usecases/{get_home_feed,get_post,get_user_posts,get_saved_posts,create_post,delete_post,like_post,unlike_post,save_post,unsave_post}.dart`, C `test/features/post/domain/create_post_test.dart`.
- **Steps**:
  1. Entities: `PostMedia(url, width?, height?)`; `Post` (T5); `PostInteraction(isLiked, likesCount, isSaved)`; `GridItem(postId, coverUrl, mediaCount, createdAt)`; `NewPostImage(filePath, width, height)`; `CreatePostInput(images: List<NewPostImage>, aspectRatio: double, caption: String, location: String)`.
  2. Repo: `getHomeFeed({Cursor? before})`, `getPost(id)`, `getUserPosts(userId, {Cursor? before})` → `PageResult<GridItem>`, `getSavedPosts({Cursor? before})` → `PageResult<GridItem>`, `createPost(CreatePostInput, {void Function(double progress)? onProgress})` → `String postId`, `deletePost(postId)`, `likePost`, `unlikePost`, `savePost`, `unsavePost` → `Unit`.
  3. `CreatePost` validates: 1..`MediaLimits.maxCarouselItems` images, caption ≤ 2200, location ≤ 100, aspect 0.8–1.91.
  4. Test: 0 images and 11 images → `ValidationFailure`; repository not called.
- **Accept**: tests pass. **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T01 post domain`

#### [ ] P4-T02 — Post data + DI
- **Read**: §3.4 T6, T7, T8, T10; §6.4 feed_post/grid_item/create_post; §6.5 post-images path. **Files**: C `lib/features/post/data/models/{post_media_model,feed_post_model,grid_item_model}.dart`, C `lib/features/post/data/datasources/post_remote_data_source.dart`, C `lib/features/post/data/repositories/post_repository_impl.dart`, C `lib/features/post/di/post_providers.dart`, C `test/features/post/data/feed_post_model_test.dart`.
- **Steps**:
  1. Models per T6; `GridItemModel.toEntity` → cover URL from `post-images`.
  2. Datasource: RPCs `get_home_feed`, `get_post` (0 rows → `Failure.notFound()`), `get_user_posts`, `get_saved_posts`, `create_post`; likes/saves = insert/delete on `post_likes`/`saved_posts` (`.eq` both keys); delete post = select `storage_path` from `post_media` → delete `posts` row → `storage.remove(post-images, paths)` best-effort.
  3. Create flow in repository: `postId = const Uuid().v4()`; for each image i: compress (`ImageCompressor`), upload to `'$uid/$postId/${i}_${uuid}.jpg'`, report `onProgress((i+1)/(n+1))`; then `create_post` RPC with `p_media` = `[{path, width, height}]`; on any failure remove uploaded paths, rethrow.
  4. Test: fixture JSON (exact §6.4 feed_post keys, media array of 2) → entity with 2 media and correct counts.
- **Accept**: tests pass. **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T02 post data layer`

#### [ ] P4-T03 — Guidelines notice + acknowledgement
- **Read**: §2.2. **Files**: C `lib/features/moderation/presentation/providers/guidelines_ack_controller.dart`, C `lib/features/moderation/presentation/widgets/guidelines_notice.dart`, M translations (`guidelines.*`).
- **Steps**: `GuidelinesAckController` (keepAlive Notifier<bool>) reads/writes `PrefsKeys.guidelinesAccepted`. `GuidelinesNotice({required bool requireAck})`: card (bg `secondaryContainer`, radius `md`, icon `shieldCheck`), text `guidelines.notice`, link "Read guidelines" → `AppRoutes.guidelines`; if `requireAck` and not accepted: `CheckboxListTile` "I agree to follow the content guidelines" that sets accepted. Expose `bool get canShare` via provider. Add keys `guidelines.title` "Content guidelines", `guidelines.intro` "Halalgram is a respectful space. Please keep these in mind:", `guidelines.item_1..7` (§2.2 verbatim, both languages), `guidelines.notice` "Please keep your content respectful and modest.", `guidelines.read` "Read guidelines", `guidelines.agree` "I agree to follow the content guidelines".
- **Accept**: analyze clean. **Verify**: VERIFY-STD.
- **Commit**: `feat(moderation): P4-T03 guidelines notice`

#### [ ] P4-T04 — Create post: pick & crop
- **Read**: `lib/core/media/media_picker.dart`. **Files**: C `lib/features/post/presentation/screens/create_post_picker_screen.dart`, C `lib/features/post/presentation/widgets/aspect_toggle.dart`, M `app_router.dart` (createPost), M translations (`post.create.*`).
- **Steps**: on first frame call `MediaPicker.pickImages(max: 10)`; cancel → pop. Show preview `PageView` of picked files + `AspectToggle` (square 1:1 / portrait 4:5; default square). "Next" → crop each file sequentially with chosen aspect (user cancel on any → stay on screen) → read dimensions with `decodeImageFromList(await file.readAsBytes())` → `context.push(AppRoutes.createPostDetails, extra: CreatePostDraft(images: [...NewPostImage], aspectRatio: 1.0 | 0.8))` (`CreatePostDraft` = simple class in `presentation/providers/create_post_draft.dart`, listed C).
- Keys: `post.create.title` "New post", `square` "Square", `portrait` "Portrait", `next` "Next".
- **Accept**: picking 3 images reaches details screen with 3 cropped files (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T04 create post picker and crop`

#### [ ] P4-T05 — Create post: details & upload
- **Read**: P4-T04 files, P4-T03 widget. **Files**: C `lib/features/post/presentation/providers/{create_post_draft,create_post_controller,feed_refresh_tick}.dart`, C `lib/features/post/presentation/screens/create_post_details_screen.dart`, M `app_router.dart`, M translations.
- **Steps**: `FeedRefreshTick` keepAlive Notifier<int> with `bump()`. Screen: horizontal thumbnails (64), caption field (multiline, max 2200), location field (max 100), `GuidelinesNotice(requireAck: true)`. App bar "Share" enabled only when guidelines accepted and not uploading. `CreatePostController` state = `AsyncValue<double?>` (progress); success → `ref.read(feedRefreshTickProvider.notifier).bump()`, `context.go(AppRoutes.home)`, snackbar `post.create.shared`. Show `LinearProgressIndicator(value: progress)` under app bar while uploading; back disabled while uploading (`PopScope(canPop: !uploading)`).
- Keys: `post.create.caption` "Write a caption…", `location` "Add location", `share` "Share", `shared` "Your post was shared.", `uploading` "Sharing…".
- **Accept**: new post appears in DB with N `post_media` rows (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T05 create post details and upload`

#### [ ] P4-T06 — PostCard (layout)
- **Read**: §4.5 Post card. **Files**: C `lib/features/post/presentation/widgets/{post_card,post_header,post_media_carousel,post_action_bar,post_caption}.dart`, M translations (`post.card.*`).
- **Steps**: build per §4.5. `PostCard({required Post post, VoidCallback? onCommentsTap, VoidCallback? onMoreTap})`. Header tap avatar/username → `AppRoutes.userProfilePath`. Carousel: `PageView` + counter chip; current page notifier passed to `SmoothPageIndicator` (`WormEffect` dot 6, active `primary`, inactive `outline`) in action bar. Likes text uses plural key `post.card.likes` (`"likes": {"zero": "Be the first to like this", "one": "1 like", "other": "{} likes"}`; AR `zero/one/two/few/many/other`) via `.plural(count)`. Caption: `ReadMoreText` (trimLines 2, `trimMode: TrimMode.Line`, more/less keys). Comments link "View all {} comments" only when count > 0. Time `formatRelative`. Uses `PostInteractionController` (created in P4-T07 — in this task read `post.isLiked/likesCount/isSaved` directly).
- Keys: `likes` (plural), `view_comments` "View all {} comments", `more` "more", `less` "less".
- **Accept**: analyze clean; check_rules OK. **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T06 post card layout`

#### [ ] P4-T07 — Likes, double-tap heart, save, share
- **Read**: §3.4 T12, P4-T06 files. **Files**: C `lib/features/post/presentation/providers/post_interaction_controller.dart`, C `lib/features/post/presentation/widgets/double_tap_heart.dart`, M `post_card.dart`, `post_action_bar.dart`, `post_media_carousel.dart`, M translations.
- **Steps**: T12 controller (+ `toggleSave()` same pattern, `likeIfNeeded()` for double-tap). `DoubleTapHeart({required Widget child, required VoidCallback onDoubleTap})`: on double tap show `HeartIcon(filled)` 96 `onMedia` animated with `flutter_animate` `.scale(begin: 0, end: 1.2, duration: 250ms).then().scale(end: 0.83, duration: 150ms).then(delay: 150ms).fadeOut(duration: 150ms)` + `HapticFeedback.lightImpact()`. Action bar heart → `toggleLike`; bookmark → `toggleSave` + snackbar `post.card.saved`/`unsaved`; send → `SharePlus.instance.share(ShareParams(text: LocaleKeys.post_card_share_text.tr(namedArgs: {'username': ..., 'caption': ...})))` (replaced by send sheet in P8-T04).
- Keys: `saved` "Saved.", `unsaved` "Removed from saved.", `share_text` "{caption}\n— @{username} on Halalgram".
- **Accept**: like toggles instantly; DB `likes_count` follows (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T07 like, save, double-tap, share`

#### [ ] P4-T08 — Home screen (feed)
- **Read**: §3.4 T14, §4.5 Home. **Files**: C `lib/features/feed/presentation/screens/home_screen.dart`, C `lib/features/feed/presentation/widgets/{home_app_bar,home_feed_list,stories_bar_slot}.dart`, M `app_router.dart` (home), M translations (`feed.*`).
- **Steps**: `CustomScrollView` + `PagingListener`: `SliverAppBar(floating: true, snap: true, toolbarHeight: AppSizes.appBarHeight)` with `HalalWordmark` (start) and actions heart → `AppRoutes.notifications`, send → `AppRoutes.inbox` (badges added in P8-T08); `SliverToBoxAdapter(StoriesBarSlot())` (SizedBox of `storiesBarHeight`, replaced in P5-T02); `SliverToBoxAdapter(OccasionBanner())` (added in P4-T09 — leave a `SizedBox.shrink()` placeholder now); `PagedSliverList` of `PostCard` (onCommentsTap → P4-T11). `RefreshIndicator` → `_paging.refresh()`. `ref.listen(feedRefreshTickProvider, (_, __) => _paging.refresh())`. Empty → `EmptyView(icon: users, messageKey: feed.empty, action: AppButton.secondary(feed.discover → AppRoutes.explore))`.
- Keys: `feed.empty` "Follow people to see their posts here.", `feed.discover` "Discover people".
- **Accept**: own posts visible in feed; pagination loads beyond 10 posts (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(feed): P4-T08 home feed`

#### [ ] P4-T09 — Occasion banner
- **Read**: `lib/core/utils/occasions.dart`. **Files**: C `lib/features/feed/presentation/providers/occasion_banner_controller.dart`, C `lib/features/feed/presentation/widgets/occasion_banner.dart`, M `home_screen.dart`, C `test/features/feed/occasion_banner_controller_test.dart`.
- **Steps**: controller `Occasion? build()` = `occasionFor(clock now)` unless prefs has `'${PrefsKeys.bannerDismissedPrefix}${occasion.name}_${yyyy-MM-dd}'`; `dismiss()` writes it and sets null. Inject time via `@Riverpod(keepAlive: true) DateTime Function() now(Ref ref) => DateTime.now;` in the same file (testable). Widget per §4.5 with title/subtitle keys and `HijriDateText`. (This replaces the `occasion_banner.dart` entry listed under core widgets in §4.6.)
- **Accept**: test: Friday + not dismissed → jumuah; after dismiss → null. **Verify**: VERIFY-STD.
- **Commit**: `feat(feed): P4-T09 occasion banner`

#### [ ] P4-T10 — Comments domain + data + DI
- **Read**: §6.4 comment_row, get_post_comments/get_comment_replies/get_reel_comments. **Files**: C `lib/features/comments/domain/entities/{comment,comment_target}.dart`, C `.../domain/repositories/comments_repository.dart`, C `.../domain/usecases/{get_comments,get_replies,add_comment,delete_comment,like_comment,unlike_comment}.dart`, C `.../data/models/comment_model.dart`, C `.../data/datasources/comments_remote_data_source.dart`, C `.../data/repositories/comments_repository_impl.dart`, C `.../di/comments_providers.dart`, C `test/features/comments/data/comment_model_test.dart`.
- **Steps**: `CommentTarget(type: CommentTargetType.post|reel, id)`; `Comment(id, parentId?, author: UserSummary, content, likesCount, repliesCount, createdAt, isLiked)`. Repo: `getComments(target, {Cursor? before})`, `getReplies(parentId, {Cursor? after})`, `addComment(target, content, {String? parentId})` → Unit, `deleteComment(target, commentId)`, `likeComment`, `unlikeComment`. `AddComment` validates 1–1000 chars (trimmed) and rejects `parentId` for reel targets. Data: post → `post_comments`, reel → `reel_comments`; likes → `comment_likes`.
- **Accept**: model test passes. **Verify**: VERIFY-STD.
- **Commit**: `feat(comments): P4-T10 comments domain and data`

#### [ ] P4-T11 — Comments sheet UI
- **Read**: §4.5 Comments sheet. **Files**: C `lib/features/comments/presentation/providers/{comment_composer_controller,comment_like_controller}.dart`, C `lib/features/comments/presentation/widgets/{comments_sheet,comment_tile,replies_section,comment_input_bar}.dart`, M `home_feed_list.dart` (onCommentsTap), M translations (`comments.*`).
- **Steps**: `Future<void> showCommentsSheet(BuildContext context, {required CommentTarget target, required String ownerId})`. Paged list (`cursorPagingController`), `CommentTile` (like toggle optimistic via family controller keyed by Comment — post targets only; Reply button → composer reply mode), `RepliesSection` (collapsed "View {} replies"; expand loads `getReplies` pages of 20; "Hide replies"), long-press: own comment or `ownerId == me` → delete confirm → refresh. `CommentInputBar` with my avatar (`profileControllerProvider(me)`), reply chip, Post button disabled when empty; after add → refresh list (and replies section) + clear input. `viewInsets` padding for keyboard.
- Keys: `comments.title` "Comments", `empty` "No comments yet. Start the conversation.", `reply` "Reply", `replying_to` "Replying to {username}", `view_replies` "View {} replies", `hide_replies` "Hide replies", `add_hint` "Add a comment…", `post` "Post", `delete_title` "Delete comment?", `deleted` "Comment deleted.".
- **Accept**: add, reply, like, delete work (manual QA, 2 accounts). **Verify**: VERIFY-STD.
- **Commit**: `feat(comments): P4-T11 comments sheet`

#### [ ] P4-T12 — Post detail screen + own post options
- **Read**: P4-T06/T07 files. **Files**: C `lib/features/post/presentation/providers/post_detail_controller.dart`, C `lib/features/post/presentation/screens/post_detail_screen.dart`, C `lib/features/post/presentation/widgets/post_options_sheet.dart`, M `app_router.dart` (postDetail), M `post_card.dart` (show ellipsis only when `post.author.id == me` until P9-T02), M translations (`post.detail.*`, `post.options.*`).
- **Steps**: `PostDetailScreen(postId)` → `PostDetailController(postId)` AsyncNotifier<Post>; body: `PostCard` + `HijriDateText(post.createdAt)` padded `md`; app bar title `post.detail.title`. Options sheet (own): Delete → confirm → `DeletePost` → `feedRefreshTick.bump()` + pop + snackbar.
- Keys: `post.detail.title` "Post", `post.options.delete` "Delete", `delete_title` "Delete this post?", `delete_message` "This can't be undone.", `deleted` "Post deleted.".
- **Accept**: delete removes post from feed after pop (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T12 post detail and delete`

#### [ ] P4-T13 — Profile posts grid + saved tab
- **Read**: `profile_tabs.dart`. **Files**: C `lib/features/post/presentation/widgets/{post_grid_tile,user_posts_grid,saved_posts_grid}.dart`, M `lib/features/profile/presentation/widgets/profile_tabs.dart`, M translations (`profile.empty_posts`, `profile.empty_saved`).
- **Steps**: grid per §4.5 (3 cols, spacing 1.5, square, `copy` icon when `mediaCount > 1`), `PagedSliverGrid` inside the tab's `CustomScrollView` (use `SliverOverlapInjector` pattern for `NestedScrollView`), tap → `AppRoutes.postDetailPath(id)`. Saved tab only for own profile.
- Keys: `profile.empty_posts` "No posts yet", `profile.empty_saved` "Save posts to see them here.".
- **Accept**: own grid shows posts; saved tab shows saved posts (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(post): P4-T13 profile grid and saved posts`

#### [ ] P4-T14 — Remove legacy post code + tests + Phase 4 DoD
- **Read**: legacy inventory. **Files**: D P4-T14 inventory row; M `analysis_options.yaml` (remove `lib/util/**`, `lib/core/database/**`, `lib/core/config/supabase_config.dart` lines); C `test/features/post/presentation/post_interaction_controller_test.dart`.
- **Steps**: `git rm` files; test: override `likePostProvider` with mock returning `left(Failure.network())` → after `toggleLike()` state equals initial (revert). Phase 4 DoD.
- **Accept**: tests pass; legacy files gone. **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `chore(post): P4-T14 remove legacy post code`

---

### Phase 5 — Stories & highlights

#### [ ] P5-T01 — Story domain + data + DI
- **Read**: §6.1 stories, §6.4 story RPCs, §6.5 story-media. **Files**: C `lib/features/story/domain/entities/{story_tray_item,story_item}.dart`, C `.../domain/repositories/story_repository.dart`, C `.../domain/usecases/{get_stories_tray,get_user_stories,create_story,mark_story_viewed,delete_story,get_story_viewers,get_my_story_archive}.dart`, C `.../data/models/{story_tray_item_model,story_item_model}.dart`, C `.../data/datasources/story_remote_data_source.dart`, C `.../data/repositories/story_repository_impl.dart`, C `.../di/story_providers.dart`, C `test/features/story/data/story_item_model_test.dart`.
- **Steps**: `StoryItem(id, mediaUrl, type: StoryMediaType.image|video, duration: Duration, createdAt, expiresAt, isViewed, viewCount)`; `StoryTrayItem(user: UserSummary, latestStoryAt, hasUnseen, isMe)`. `CreateStory(filePath, type, durationMs)` validates video ≤ 30 s and file size ≤ 50 MB (size passed in input). Data: image → compress then upload `story-media/{uid}/{storyId}/{uuid}.jpg`; video → upload as-is `.mp4`; insert `stories` row with client `id`. Delete = delete row then remove file best-effort.
- **Accept**: model test passes. **Verify**: VERIFY-STD.
- **Commit**: `feat(story): P5-T01 story domain and data`

#### [ ] P5-T02 — Stories bar on Home
- **Read**: §4.5 Stories bar. **Files**: C `lib/features/story/presentation/providers/stories_tray_controller.dart`, C `lib/features/story/presentation/widgets/{stories_bar,story_tray_tile}.dart`, M `lib/features/feed/presentation/screens/home_screen.dart` (replace slot), D `lib/features/feed/presentation/widgets/stories_bar_slot.dart`, M translations (`story.*`).
- **Steps**: controller AsyncNotifier<List<StoryTrayItem>>; refresh with feed pull-to-refresh (`ref.invalidate`). First tile always "Your story": my avatar + plus badge; tap → if I have active stories open viewer else `AppRoutes.createStory`; plus badge tap → createStory. Others: `StoryRing(seen: !hasUnseen)` → `AppRoutes.storyViewerPath(userId)`. Loading → skeleton circles.
- Keys: `story.your_story` "Your story".
- **Accept**: followed users with stories appear; seen ring changes after viewing (after P5-T04). **Verify**: VERIFY-STD.
- **Commit**: `feat(story): P5-T02 stories bar`

#### [ ] P5-T03 — Create story
- **Read**: `media_picker.dart`, P4-T03 widget. **Files**: C `lib/features/story/presentation/providers/create_story_controller.dart`, C `lib/features/story/presentation/screens/create_story_screen.dart`, M `app_router.dart`, M translations (`story.create.*`).
- **Steps**: on open `MediaPicker.pickImageOrVideo` (+ app bar camera icon → capture image). Preview full-screen on black (image `BoxFit.contain`; video `VideoPlayer` looping, read duration & file length; > 30 s or > 50 MB → error snackbar + pop). Bottom: small `GuidelinesNotice(requireAck: false)` + primary "Share to your story" → upload with progress → invalidate tray → pop + snackbar. Dark theme.
- Keys: `story.create.share` "Share to your story", `too_long` "Story videos can be up to 30 seconds.", `too_large` "This file is too large.", `shared` "Added to your story.".
- **Accept**: story visible in tray for followers (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(story): P5-T03 create story`

#### [ ] P5-T04 — Story viewer
- **Read**: §4.5 Story viewer, §4.7. **Files**: C `lib/features/story/presentation/providers/story_viewer_controller.dart`, C `lib/features/story/presentation/widgets/{story_player,story_header,story_viewers_sheet,story_options_sheet}.dart`, C `lib/features/story/presentation/screens/story_viewer_screen.dart`, M `app_router.dart`, M translations (`story.viewer.*`).
- **Steps**:
  1. `StoryPlayer({required List<StoryItem> items, required VoidCallback onComplete, required void Function(StoryItem) onShow, required Widget Function(StoryItem) headerBuilder, Widget Function(StoryItem)? footerBuilder})` wraps `StoryView` (in `Directionality(ltr)`) with `StoryItem.pageImage(url:, controller:, duration:)` / `StoryItem.pageVideo(url, controller:, duration:)`; header/footer overlaid in a `Stack` above it; `StoryController` disposed. Match the installed `story_view` callback signatures (STOP if `onStoryShow` signature differs from what compiles).
  2. Pure function `String? nextTrayUserId(List<StoryTrayItem> tray, String currentUserId)` in controller file.
  3. Screen: loads `getUserStories(userId)`; `onShow` → `markStoryViewed` (skip own); `onComplete` → next user via `context.replace(storyViewerPath(next))` or pop; after pop invalidate tray. Owner footer "Seen by {}" (`eye`) → `StoryViewersSheet`; owner header ellipsis → `StoryOptionsSheet` (Delete; "Add to highlight" → `AppRoutes.highlightEditor` with query `story=<id>`). Vertical drag down → pop.
- Keys: `story.viewer.seen_by` "Seen by {}", `viewers` "Viewers", `delete` "Delete story", `delete_title` "Delete this story?", `add_highlight` "Add to highlight".
- **Accept**: tap advances, completion moves to next user, view recorded once (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(story): P5-T04 story viewer`

#### [ ] P5-T05 — Highlights domain + data
- **Read**: §6.4 highlight RPCs. **Files**: C `lib/features/story/domain/entities/highlight.dart`, M `story_repository.dart` (add methods), C `.../domain/usecases/{get_user_highlights,get_highlight_stories,save_highlight,delete_highlight}.dart`, C `.../data/models/highlight_model.dart`, M datasource, repository impl, `story_providers.dart`.
- **Steps**: `Highlight(id, title, coverUrl?, itemCount)`; `SaveHighlight(id?, title, storyIds)` validates title 1–30 and ≥ 1 story. Delete = `from('highlights').delete().eq('id', id)`.
- **Accept**: analyze clean. **Verify**: VERIFY-STD.
- **Commit**: `feat(story): P5-T05 highlights domain and data`

#### [ ] P5-T06 — Highlights row + highlight viewer
- **Read**: `story_player.dart`, `profile_header.dart`. **Files**: C `lib/features/story/presentation/providers/highlights_controller.dart`, C `lib/features/story/presentation/widgets/{highlights_row,highlight_circle}.dart`, C `lib/features/story/presentation/screens/highlight_viewer_screen.dart`, M `lib/features/profile/presentation/widgets/profile_header.dart` (insert row under actions), M `app_router.dart`, M translations (`highlight.*`).
- **Steps**: row hidden when empty and not own; own shows "New" circle (plus) first → `AppRoutes.highlightEditor`. Circle 64 with cover + title `bodySmall`. Tap → viewer (`StoryPlayer`, no next-user). Long-press own → sheet Edit (`highlightEditor?id=`) / Delete (confirm).
- Keys: `highlight.new` "New", `edit` "Edit highlight", `delete` "Delete highlight", `delete_title` "Delete this highlight?".
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(story): P5-T06 highlights row and viewer`

#### [ ] P5-T07 — Highlight editor
- **Read**: P5-T05 files. **Files**: C `lib/features/story/presentation/providers/highlight_editor_controller.dart`, C `lib/features/story/presentation/screens/highlight_editor_screen.dart`, M `app_router.dart`, M translations (`highlight.editor.*`).
- **Steps**: title field (max 30) + paged grid of `getMyStoryArchive` (3 cols, 9:16 tiles; video tiles show play icon); multi-select with order badge (1, 2, 3…); query `id` → load existing items preselected; query `story` → preselect that story. Save (enabled when title valid and ≥1 selected) → `SaveHighlight` → invalidate highlights → pop.
- Keys: `highlight.editor.title_new` "New highlight", `title_edit` "Edit highlight", `name` "Highlight name", `save` "Save", `archive_empty` "Your stories will appear here.".
- **Accept**: create + edit work (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(story): P5-T07 highlight editor`

#### [ ] P5-T08 — Story tests + Phase 5 DoD
- **Read**: P5-T04 `nextTrayUserId`, P5-T01 `CreateStory`, §8 Phase 5. **Files**: C `test/features/story/presentation/next_tray_user_test.dart`, C `test/features/story/domain/create_story_test.dart`.
- **Steps**: `nextTrayUserId` (middle, last → null, unknown → first unseen or null per implementation — document chosen behavior in the test name); `CreateStory` rejects 31-second video. Phase 5 DoD.
- **Accept**: tests pass. **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `test(story): P5-T08 story tests and phase 5 DoD`

---

### Phase 6 — Reels (no music: original audio or muted only)

#### [ ] P6-T01 — Reel domain + data + DI
- **Read**: §6.1 reels, §6.4 reel_row, §6.5 reel-videos. **Files**: C `lib/features/reel/domain/entities/{reel,reel_interaction,new_reel_input}.dart`, C `.../domain/repositories/reel_repository.dart`, C `.../domain/usecases/{get_reels_feed,get_user_reels,create_reel,delete_reel,like_reel,unlike_reel}.dart`, C `.../data/models/reel_model.dart`, C `.../data/datasources/reel_remote_data_source.dart`, C `.../data/repositories/reel_repository_impl.dart`, C `.../di/reel_providers.dart`, C `test/features/reel/data/reel_model_test.dart`.
- **Steps**: `Reel` = reel_row camelCase with `videoUrl`, `thumbnailUrl`, `author: UserSummary`, `duration: Duration`. `NewReelInput(videoPath, thumbnailPath, caption, durationMs, width, height, isMuted, fileSizeBytes)`; `CreateReel` validates ≤ 90 s, ≤ 100 MB, caption ≤ 2200. Data: `reelId = uuid v4`; upload video `reel-videos/{uid}/{reelId}/video_{uuid}.mp4` and thumb `.../thumb_{uuid}.jpg`; insert `reels` row (`id, user_id, video_path, thumbnail_path, caption, duration_ms, width, height, is_muted`); failure → remove uploads. Delete = select paths, delete row, remove files.
- **Accept**: model test passes. **Verify**: VERIFY-STD.
- **Commit**: `feat(reel): P6-T01 reel domain and data`

#### [ ] P6-T02 — Video controller pool + mute state
- **Read**: none. **Files**: C `lib/core/media/video_controller_pool.dart`, C `lib/features/reel/presentation/providers/{reels_video_pool,reels_muted_controller}.dart`, C `test/core/media/video_controller_pool_test.dart`.
- **Steps**: `VideoControllerPool({VideoPlayerController Function(String url)? factory, int maxSize = 3})`; `Future<VideoPlayerController> obtain(String url)` (create via factory, default `VideoPlayerController.networkUrl(Uri.parse(url))`, `initialize()`, `setLooping(true)`, cache); `void retainOnly(Set<String> urls)` disposes others; `Future<void> disposeAll()`. Provider `reelsVideoPool` (autoDispose, `ref.onDispose(pool.disposeAll)`). `ReelsMutedController` keepAlive Notifier<bool> persisted in `PrefsKeys.reelsMuted`. Test with mocktail `VideoPlayerController` mocks: obtain 4 urls then `retainOnly({u3,u4})` → u1/u2 `dispose()` called.
- **Accept**: test passes. **Verify**: VERIFY-STD.
- **Commit**: `feat(reel): P6-T02 video controller pool`

#### [ ] P6-T03 — Reels screen (vertical pager, autoplay)
- **Read**: §4.5 Reels, P6-T02 files. **Files**: C `lib/features/reel/presentation/widgets/{reels_pager,reel_player_view}.dart`, C `lib/features/reel/presentation/screens/reels_screen.dart`, M `app_router.dart` (reels branch), M translations (`reel.*`).
- **Steps**: `ReelsPager({required PagingController<int, Reel> paging, int initialIndex = 0})` — `PagingListener` + `PageView.builder(scrollDirection: vertical)` over `state.items`; `onPageChanged(i)`: when `i >= items.length - 2` call `fetchNextPage`; `pool.retainOnly({items[i-1], items[i], items[i+1]} urls)`. `ReelPlayerView(reel, isActive)`: thumbnail until initialized; plays when `isActive` AND `VisibilityDetector` fraction > 0.6; volume 0 when `reel.isMuted || muted`; tap toggles global mute (brief center icon `volumeX/volume2`); long-press pauses; bottom 2px progress (`VideoProgressIndicator`). Screen: `Theme(data: AppTheme.dark())`, transparent app bar title `nav.reels` + camera icon → `AppRoutes.createReel`. Pause all when branch not visible (VisibilityDetector on screen root).
- Keys: `reel.empty` "No reels yet.".
- **Accept**: swipe plays next, previous pauses; leaving tab stops audio (manual QA on device). **Verify**: VERIFY-STD.
- **Commit**: `feat(reel): P6-T03 reels pager with autoplay`

#### [ ] P6-T04 — Reel overlay & interactions
- **Read**: §4.5 Reels. **Files**: C `lib/features/reel/presentation/providers/reel_interaction_controller.dart`, C `lib/features/reel/presentation/widgets/{reel_overlay,reel_actions_column,reel_author_row,reel_audio_label,reel_options_sheet}.dart`, M `reel_player_view.dart`, M translations.
- **Steps**: overlay per §4.5 on `mediaScrim` bottom gradient; actions: heart (optimistic, T12 pattern), comment (count; P6-T05), send (external share `reel.share_text`), ellipsis (own → delete confirm; others hidden until P9-T02). Double-tap → like + heart animation (reuse `DoubleTapHeart`). Author row: avatar+username → profile; follow button placeholder hidden (P7-T02 wires). `ReelAudioLabel`: `audioLines` + `reel.original_audio` or `reel.muted`.
- Keys: `reel.original_audio` "Original audio", `muted` "Muted", `share_text` "Watch @{username}'s reel on Halalgram", `delete_title` "Delete this reel?", `deleted` "Reel deleted.".
- **Accept**: like/double-tap/delete work (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(reel): P6-T04 reel overlay and interactions`

#### [ ] P6-T05 — Reel comments
- **Read**: `comments_sheet.dart`. **Files**: M `reel_actions_column.dart`, M `comment_tile.dart` (hide like/reply when `target.type == reel`).
- **Steps**: comment icon → `showCommentsSheet(target: CommentTarget(type: reel, id), ownerId: reel.author.id)`; pause video while sheet open, resume after.
- **Accept**: comment on reel increments count after refresh (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(reel): P6-T05 reel comments`

#### [ ] P6-T06 — Create reel (original audio or muted)
- **Read**: `media_picker.dart`, P4-T03 widget. **Files**: C `lib/features/reel/presentation/providers/create_reel_controller.dart`, C `lib/features/reel/presentation/screens/create_reel_screen.dart`, C `lib/features/reel/presentation/widgets/audio_mode_toggle.dart`, M `app_router.dart`, M translations (`reel.create.*`).
- **Steps**: open → `MediaPicker.pickVideo` (app bar camera → `captureVideo(maxDuration: 90 s)`); read duration/size/width/height via `VideoPlayerController.file` + `File.length()`; invalid → snackbar + pop. Preview 9:16 looped. `AudioModeToggle` segmented: Original audio / Muted (no other option) + info text `reel.create.no_music`. Caption field, `GuidelinesNotice(requireAck: true)`. Thumbnail: `FcNativeVideoThumbnail().getVideoThumbnail(srcFile: path, destFile: '<temp>/<uuid>.jpg', width: 720, height: 1280, format: 'jpeg', quality: 80)` (STOP if API differs). Share → upload with progress → `context.go(AppRoutes.reels)` + snackbar.
- Keys: `reel.create.title` "New reel", `original_audio` "Original audio", `muted` "Muted", `no_music` "Music tracks aren't allowed. Use your original audio or mute.", `caption` "Write a caption…", `share` "Share", `too_long` "Reels can be up to 90 seconds.", `too_large` "This video is too large (max 100 MB).", `shared` "Your reel was shared.".
- **Accept**: reel appears in reels feed with thumbnail (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(reel): P6-T06 create reel`

#### [ ] P6-T07 — Profile reels tab + user reels pager
- **Read**: `profile_tabs.dart`, `reels_pager.dart`. **Files**: C `lib/features/reel/presentation/widgets/user_reels_grid.dart`, C `lib/features/reel/presentation/screens/user_reels_screen.dart`, M `profile_tabs.dart`, M `app_router.dart` (userReels), M translations (`profile.empty_reels`).
- **Steps**: grid 3 cols 9:16 thumbnails with `play` icon; tap index i → `AppRoutes.userReelsPath(userId, index: i)`. `UserReelsScreen` builds a `cursorPagingController` over `getUserReels(userId)`, pre-fetches pages until `items.length > index` then shows `ReelsPager(initialIndex: index)`.
- Keys: `profile.empty_reels` "No reels yet".
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(reel): P6-T07 profile reels tab`

#### [ ] P6-T08 — Remove legacy reels + Phase 6 DoD
- **Read**: legacy inventory row for P6-T08, `analysis_options.yaml`, §8 Phase 6. **Files**: D P6-T08 inventory row; M `analysis_options.yaml` (remove `lib/widgets/**`); C `test/features/reel/domain/create_reel_test.dart`.
- **Steps**: `git rm`; test `CreateReel` rejects 91 s and 101 MB. Phase 6 DoD.
- **Accept**: tests pass. **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `chore(reel): P6-T08 remove legacy reels code`

---

### Phase 7 — Explore, search, follow

#### [ ] P7-T01 — Follow domain + data + DI
- **Read**: §6.4 follow RPCs, user_row. **Files**: C `lib/features/follow/domain/entities/{follow_status,user_list_item}.dart`, C `.../domain/repositories/follow_repository.dart`, C `.../domain/usecases/{follow_user,unfollow_user,get_followers,get_following,get_follow_requests,accept_follow_request,decline_follow_request,remove_follower}.dart`, C `.../data/models/user_row_model.dart`, C `.../data/datasources/follow_remote_data_source.dart`, C `.../data/repositories/follow_repository_impl.dart`, C `.../di/follow_providers.dart`, C `test/features/follow/data/user_row_model_test.dart`.
- **Steps**: `enum FollowStatus { none, following, requested }` + `static FollowStatus fromProfile({required bool isFollowing, required bool isRequested})`; `UserListItem(user: UserSummary, isPrivate, isFollowing, createdAt)`. `followUser` maps RPC text → enum. Lists return `PageResult<UserListItem>` keyed by `(createdAt, user.id)`. `UserRowModel` is used only inside `follow/data`. Explore defines its own `SearchUserModel` (P7-T05) because features never import another feature's `data/` layer; sharing `follow/domain` entities is allowed.
- **Accept**: test passes. **Verify**: VERIFY-STD.
- **Commit**: `feat(follow): P7-T01 follow domain and data`

#### [ ] P7-T02 — Follow button (profile, reels)
- **Read**: `profile_actions.dart`, `reel_author_row.dart`. **Files**: C `lib/features/follow/presentation/providers/follow_controller.dart`, C `lib/features/follow/presentation/widgets/{follow_button,unfollow_sheet}.dart`, M `profile_actions.dart`, M `reel_author_row.dart`, M translations (`follow.*`).
- **Steps**: `FollowController` family(userId, FollowStatus initial) optimistic: none → following|requested (server result), following → confirm `UnfollowSheet` (private account warning text) → none, requested → cancel request → none. Invalidate `profileControllerProvider(userId)` after success. `FollowButton({required String userId, required FollowStatus initial, bool followsMe = false, FollowButtonVariant variant = profile|compact|reel})`: labels Follow / Follow back (when `followsMe`) / Following / Requested; styles: follow = primary filled, others = secondary. Profile (other): replace placeholder; reel: show only if `!isFollowingAuthor` and not own.
- Keys: `follow.follow` "Follow", `follow_back` "Follow back", `following` "Following", `requested` "Requested", `unfollow` "Unfollow", `unfollow_title` "Unfollow @{username}?", `unfollow_private` "You'll need to request again to see their posts.", `cancel_request` "Cancel request".
- **Accept**: follow public → following; follow private → requested (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(follow): P7-T02 follow button`

#### [ ] P7-T03 — Followers / following screen
- **Read**: §4.5 lists. **Files**: C `lib/features/follow/presentation/widgets/{user_list_tile,connections_list}.dart`, C `lib/features/follow/presentation/screens/connections_screen.dart`, M `app_router.dart`, M translations (`follow.connections.*`).
- **Steps**: `DefaultTabController` 2 tabs (initial from query `tab`), title = username; each tab paged list of `UserListTile` (avatar 44, username `titleSmall`, full name `bodySmall`, trailing `FollowButton(compact)` unless me). Own followers tab: trailing extra "Remove" text button → confirm → `RemoveFollower` → refresh. Top filter field filters loaded items locally (username/full name contains).
- Keys: `follow.connections.followers` "Followers", `following` "Following", `remove` "Remove", `remove_title` "Remove this follower?", `search` "Search", `empty` "No one here yet.".
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(follow): P7-T03 followers and following lists`

#### [ ] P7-T04 — Follow requests screen
- **Read**: P7-T03 files. **Files**: C `lib/features/follow/presentation/screens/follow_requests_screen.dart`, M `app_router.dart`, M `lib/features/profile/presentation/widgets/profile_menu_sheet.dart` (add "Follow requests" item when own profile is private), M translations (`follow.requests.*`).
- **Steps**: paged list; each row Confirm (primary) / Delete (secondary) → accept/decline → remove row locally + invalidate own profile.
- Keys: `follow.requests.title` "Follow requests", `confirm` "Confirm", `delete` "Delete", `empty` "No pending requests.".
- **Accept**: accepting makes requester a follower (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(follow): P7-T04 follow requests`

#### [ ] P7-T05 — Explore domain + data (grid, search, recent searches)
- **Read**: §6.4 get_explore_posts, search_profiles. **Files**: C `lib/features/explore/domain/repositories/explore_repository.dart`, C `.../domain/usecases/{get_explore_posts,search_profiles,get_recent_searches,add_recent_search,remove_recent_search,clear_recent_searches}.dart`, C `.../data/models/search_user_model.dart`, C `.../data/datasources/{explore_remote_data_source,recent_searches_local_data_source}.dart`, C `.../data/repositories/explore_repository_impl.dart`, C `.../di/explore_providers.dart`, C `test/features/explore/data/recent_searches_local_data_source_test.dart`.
- **Steps**: explore grid returns `PageResult<GridItem>` (post domain entity). Search returns `List<UserListItem>` (follow domain entity). Recent searches: JSON list of `{id, username, full_name, avatar_url}` in `PrefsKeys.recentSearches`, newest first, dedupe by id, max `AppConstants.recentSearchesMax`. `SearchProfiles` returns empty list for trimmed query length 0. `explore_providers.dart` exposes (keepAlive) `exploreRepositoryProvider` plus one provider per use case, named `<useCaseCamel>Provider` (e.g. `searchProfilesProvider`, `getExplorePostsProvider`) — other features may read `searchProfilesProvider`.
- **Accept**: local datasource test (add 11 → keeps 10; re-add moves to top). **Verify**: VERIFY-STD.
- **Commit**: `feat(explore): P7-T05 explore and search data`

#### [ ] P7-T06 — Explore screen (quilted grid)
- **Read**: `post_grid_tile.dart`. **Files**: C `lib/features/explore/presentation/screens/explore_screen.dart`, C `lib/features/explore/presentation/widgets/{explore_search_field,explore_grid}.dart`, M `app_router.dart` (explore branch), M translations (`explore.*`).
- **Steps**: top read-only search field (radius `md`, `search` icon, hint) → `AppRoutes.search`. `PagedSliverGrid` with `SliverQuiltedGridDelegate(crossAxisCount: 3, mainAxisSpacing: AppSizes.gridSpacing, crossAxisSpacing: AppSizes.gridSpacing, repeatPattern: QuiltedGridRepeatPattern.inverted, pattern: [QuiltedGridTile(2, 1), QuiltedGridTile(1, 1), QuiltedGridTile(1, 1), QuiltedGridTile(1, 1), QuiltedGridTile(1, 1)])` of `PostGridTile`. Pull to refresh.
- Keys: `explore.search_hint` "Search", `explore.empty` "Nothing to explore yet.".
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(explore): P7-T06 explore grid`

#### [ ] P7-T07 — Search screen
- **Read**: P7-T05 files, `debouncer.dart`. **Files**: C `lib/features/explore/presentation/providers/{search_query_controller,search_results_controller,recent_searches_controller}.dart`, C `lib/features/explore/presentation/screens/search_screen.dart`, M `app_router.dart`, M translations (`explore.search.*`).
- **Steps**: autofocus field in app bar with clear button; query debounced 300 ms; empty query → recent list (remove `x`, header with "Clear all"); results → `UserListTile` (no follow button); tap → add recent + push profile. Loading → `ListTileSkeleton`s; no results → EmptyView.
- Keys: `explore.search.recent` "Recent", `clear_all` "Clear all", `no_results` "No accounts found.".
- **Accept**: search by username prefix and full-name prefix works (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(explore): P7-T07 search screen`

#### [ ] P7-T08 — Remove legacy explore + tests + Phase 7 DoD
- **Read**: legacy inventory row for P7-T08, `analysis_options.yaml`, §8 Phase 7. **Files**: D P7-T08 inventory row; M `analysis_options.yaml` (remove `lib/screen/**`); C `test/core/utils/debouncer_test.dart`, C `test/features/follow/presentation/follow_controller_test.dart`.
- **Steps**: `git rm`; debouncer test with `fakeAsync`; follow controller: failure reverts state. Phase 7 DoD.
- **Accept**: tests pass; `ls lib/screen 2>/dev/null` prints nothing. **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `chore(explore): P7-T08 remove legacy explore code`

---

### Phase 8 — Chat (realtime) & notifications

#### [ ] P8-T01 — Chat domain + data + DI
- **Read**: §3.4 T15, §6.1 chat tables, §6.4 chat RPCs, §6.5 chat-media. **Files**: C `lib/features/chat/domain/entities/{conversation,message,shared_post_preview}.dart`, C `.../domain/repositories/chat_repository.dart`, C `.../domain/usecases/{get_conversations,open_direct_conversation,get_messages,send_text_message,send_image_message,send_post_message,watch_new_messages,mark_conversation_read,delete_message}.dart`, C `.../data/models/{conversation_model,message_model}.dart`, C `.../data/datasources/chat_remote_data_source.dart`, C `.../data/repositories/chat_repository_impl.dart`, C `.../di/chat_providers.dart`, C `test/features/chat/data/message_model_test.dart`.
- **Steps**: `Conversation(id, otherUser: UserSummary, lastMessageAt?, preview, lastKind: MessageKind?, lastSenderId?, isUnread)`; `Message(id, conversationId, senderId, kind: MessageKind.text|image|post, body?, mediaUrl?, sharedPost: SharedPostPreview?(postId, coverUrl?, authorUsername?), createdAt)`. `MessageModel.fromJson` (RPC keys) and `MessageModel.fromRealtime` (table keys: `id, conversation_id, sender_id, kind, body, media_path, shared_post_id, created_at`). Image URLs: `StorageService.signedUrls(chat-media, paths)` per page; realtime image → `signedUrl`; realtime post → `get_post` RPC for cover/author (0 rows → `sharedPost` with null cover). Send image: compress → upload `chat-media/{uid}/{conversationId}/{uuid}.jpg` → insert message. `SendTextMessage` validates 1–2000 trimmed. `watchNewMessages` per T15 returning `Stream<Message>` (repository maps model → entity; errors forwarded).
- **Accept**: model test for both factories. **Verify**: VERIFY-STD.
- **Commit**: `feat(chat): P8-T01 chat domain and data`

#### [ ] P8-T02 — Inbox screen + start conversation + profile Message button
- **Read**: P8-T01 files, `user_list_tile.dart`. **Files**: C `lib/features/chat/presentation/screens/inbox_screen.dart`, C `lib/features/chat/presentation/widgets/{conversation_tile,new_message_sheet}.dart`, M `profile_actions.dart` (Message → `OpenDirectConversation` → push chat), M `app_router.dart`, M translations (`chat.inbox.*`).
- **Steps**: app bar title `chat.inbox.title`; end icon `squarePen` → `NewMessageSheet` (search field using explore `searchProfilesProvider`, tap → open conversation → push `AppRoutes.chatPath(id)`). Paged conversations list; tile: avatar 44, username (bold when unread), preview text (text → body; image → `chat.preview.image`; post → `chat.preview.post`; prefixed `chat.preview.you` when `lastSenderId == me`), relative time, unread dot. Pull to refresh; the refresh-on-new-activity listener is added in P8-T08 (not now).
- Keys: `chat.inbox.title` "Messages", `new_message` "New message", `empty` "No messages yet.", `chat.preview.image` "Sent a photo", `post` "Shared a post", `you` "You: ".
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(chat): P8-T02 inbox and new message`

#### [ ] P8-T03 — Chat screen (realtime)
- **Read**: §4.5 Chat. **Files**: C `lib/features/chat/presentation/providers/{chat_thread_controller,incoming_messages}.dart`, C `lib/features/chat/presentation/screens/chat_screen.dart`, C `lib/features/chat/presentation/widgets/{message_bubble,chat_input_bar,date_separator}.dart`, M `app_router.dart`, M translations (`chat.thread.*`).
- **Steps**: `incomingMessagesProvider(conversationId)` = StreamProvider over `WatchNewMessages`. Screen holds `cursorPagingController` (newest first) + `List<Message> live` from `ref.listen(incomingMessagesProvider(id), ...)`; display list = `mergeMessages(live, paged)`; `ListView(reverse: true)`. Pure function `List<Message> mergeMessages(List<Message> live, List<Message> paged)` (dedupe by id, sorted newest first) in controller file. `markConversationRead` on open and on each incoming message from the other user. Bubbles §4.5; date separators between days (`formatFullDate`). Input bar: image button → pick 1 image → send image; text + Send (disabled when empty). Long-press own → unsend (confirm → delete → remove locally). App bar: avatar + username → profile.
- Keys: `chat.thread.hint` "Message…", `send` "Send", `unsend` "Unsend", `unsend_title` "Unsend this message?", `photo` "Photo", `post_unavailable` "This post is unavailable.".
- **Accept**: two devices exchange messages live (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(chat): P8-T03 realtime chat thread`

#### [ ] P8-T04 — Send post to DM (share sheet)
- **Read**: `post_action_bar.dart`, P8-T02 files. **Files**: C `lib/features/chat/presentation/widgets/send_post_sheet.dart`, M `post_action_bar.dart` (send icon → sheet), M translations (`chat.send_post.*`).
- **Steps**: `showSendPostSheet(context, post)`: search field (search profiles) + first page of conversations; each row trailing "Send" → open conversation + `SendPostMessage` → "Sent" disabled state; bottom row "Share externally" → existing share_plus text.
- Keys: `chat.send_post.title` "Share", `send` "Send", `sent` "Sent", `external` "Share externally".
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(chat): P8-T04 send post to messages`

#### [ ] P8-T05 — Shared post bubble
- **Read**: `message_bubble.dart`. **Files**: C `lib/features/chat/presentation/widgets/shared_post_bubble.dart`, M `message_bubble.dart`.
- **Steps**: card 220 wide (use `AppSizes` — add `sharedPostCardWidth = 220` to `app_sizes.dart`, listed M): cover square image + `@author` line; tap → `AppRoutes.postDetailPath`. Null sharedPost or null cover → `chat.thread.post_unavailable`.
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(chat): P8-T05 shared post bubble`

#### [ ] P8-T06 — Notifications domain + data + DI
- **Read**: §6.1 notifications, §6.4 notification RPCs. **Files**: C `lib/features/notifications/domain/entities/{app_notification,unread_counts}.dart`, C `.../domain/repositories/notifications_repository.dart`, C `.../domain/usecases/{get_notifications,mark_notifications_read,get_unread_counts,watch_activity}.dart`, C `.../data/models/notification_model.dart`, C `.../data/datasources/notifications_remote_data_source.dart`, C `.../data/repositories/notifications_repository_impl.dart`, C `.../di/notifications_providers.dart`, C `test/features/notifications/data/notification_model_test.dart`.
- **Steps**: `enum NotificationType` mirrors DB values (`postLike` ↔ `'post_like'`, …). `AppNotification(id, type, actor: UserSummary, postId?, postCoverUrl?, reelId?, reelThumbnailUrl?, commentId?, createdAt, isRead, isFollowingActor)`. `UnreadCounts(notifications, conversations)`. `WatchActivity` → `Stream<void>` that emits on realtime INSERT into `notifications` (filter `recipient_id=eq.<uid>`) or `messages` (no filter; RLS limits rows).
- **Accept**: model test (unknown type string → mapped to `null` and row skipped). **Verify**: VERIFY-STD.
- **Commit**: `feat(notifications): P8-T06 notifications domain and data`

#### [ ] P8-T07 — Notifications screen
- **Read**: P8-T06 files, `follow_button.dart`. **Files**: C `lib/features/notifications/presentation/providers/notification_sections.dart`, C `lib/features/notifications/presentation/screens/notifications_screen.dart`, C `lib/features/notifications/presentation/widgets/{notification_tile,follow_requests_row}.dart`, M `app_router.dart`, M translations (`notifications.*`).
- **Steps**: pure function `List<NotificationSection> groupNotifications(List<AppNotification>, DateTime now)` → Today / This week (last 7 days) / Earlier. Top `FollowRequestsRow` (shown when own profile is private) → `AppRoutes.followRequests`. Tile: avatar 44, rich text (`bidiSafe(username)` bold + action text by type), time; trailing: post/reel thumbnail 44 or `FollowButton(compact)` for `follow`; tap: post types → post detail; reel types → `AppRoutes.userReelsPath(me, index: 0)`; follow types → actor profile. Call `MarkNotificationsRead` on open, then invalidate unread counts.
- Keys: `notifications.title` "Notifications", `today` "Today", `this_week` "This week", `earlier` "Earlier", `empty` "No notifications yet.", `follow_requests` "Follow requests", `type.post_like` "liked your post.", `post_comment` "commented on your post.", `comment_reply` "replied to your comment.", `comment_like` "liked your comment.", `reel_like` "liked your reel.", `reel_comment` "commented on your reel.", `follow` "started following you.", `follow_request` "requested to follow you.", `follow_accept` "accepted your follow request.".
- **Accept**: like from account B shows on A (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(notifications): P8-T07 notifications screen`

#### [ ] P8-T08 — Unread badges (realtime)
- **Read**: `home_app_bar.dart`, `inbox_screen.dart`. **Files**: C `lib/features/notifications/presentation/providers/unread_counts_controller.dart`, M `home_app_bar.dart`, M `inbox_screen.dart` (listen → refresh), M `chat_screen.dart` (invalidate after mark read).
- **Steps**: keepAlive AsyncNotifier<UnreadCounts> (generated name `unreadCountsControllerProvider`; `inbox_screen.dart` does `ref.listen(unreadCountsControllerProvider, (_, _) => pagingController.refresh())`): load on build; subscribe `WatchActivity` (cancel on dispose) → refetch (debounced 500 ms); `AppLifecycleListener(onResume: refetch)`. Heart shows `BadgeDot` when notifications > 0; send icon shows `CountBadge(conversations)` when > 0.
- **Accept**: badge appears without restart when B sends a message (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(notifications): P8-T08 realtime unread badges`

#### [ ] P8-T09 — Chat/notification tests + Phase 8 DoD
- **Read**: P8-T03 `mergeMessages`, P8-T07 `groupNotifications`, §8 Phase 8. **Files**: C `test/features/chat/presentation/merge_messages_test.dart`, C `test/features/notifications/presentation/group_notifications_test.dart`.
- **Steps**: dedupe & order test; grouping boundary test (exactly 7 days → this week). Phase 8 DoD.
- **Accept**: tests pass. **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `test(chat): P8-T09 chat and notifications tests`

---

### Phase 9 — Moderation, settings, polish, Firebase removal, release

#### [ ] P9-T01 — Moderation domain + data + DI
- **Read**: §6.1 blocks/reports. **Files**: C `lib/features/moderation/domain/entities/{report_target_type,report_reason}.dart`, C `.../domain/repositories/moderation_repository.dart`, C `.../domain/usecases/{report_content,block_user,unblock_user,get_blocked_users}.dart`, C `.../data/datasources/moderation_remote_data_source.dart`, C `.../data/repositories/moderation_repository_impl.dart`, C `.../di/moderation_providers.dart`, C `test/features/moderation/domain/report_content_test.dart`.
- **Steps**: enums with `dbValue` getters (§6.1 check lists; `postComment` → `'post_comment'`, `falseInfo` → `'false_info'`). Report insert; duplicate (`ConflictFailure`) surfaced as-is. Blocked list: `from('blocks').select('blocked_id, profiles!blocks_blocked_id_fkey(id, username, full_name, avatar_path)')` → `List<UserSummary>`. `ReportContent` validates details ≤ 500.
- **Accept**: test passes. **Verify**: VERIFY-STD.
- **Commit**: `feat(moderation): P9-T01 moderation domain and data`

#### [ ] P9-T02 — Report sheet + block flows wired everywhere
- **Read**: files listed below. **Files**: C `lib/features/moderation/presentation/widgets/{report_sheet,block_dialog}.dart`, C `lib/features/moderation/presentation/providers/block_controller.dart`, M `post_card.dart` + `post_options_sheet.dart` (others: Report, Block), M `reel_actions_column.dart` + `reel_options_sheet.dart` (others: Report, Block), M `comment_tile.dart` (others long-press: Report), M `profile_screen.dart` (other: ellipsis sheet → Report, Block/Unblock, Remove follower if follows me), M `story_options_sheet.dart` + `story_header.dart` (others: Report), M `chat_screen.dart` (others' message long-press: Report), M translations (`moderation.*`).
- **Steps**: `showReportSheet(context, {required ReportTargetType type, required String targetId})`: reasons list → optional details field → Submit → "Thanks for letting us know" view; `ConflictFailure` → `moderation.already_reported`. `showBlockDialog(context, {userId, username})`: explanation → Block → `BlockUser` → `feedRefreshTick.bump()`, invalidate profile, pop to home, snackbar.
- Keys: `moderation.report_title` "Why are you reporting this?", `reason.spam` "Spam", `nudity` "Nudity or indecent content", `hate` "Hate speech or mocking religion", `violence` "Violence", `harassment` "Harassment or bullying", `false_info` "False information", `music` "Contains music", `other` "Something else", `details_hint` "Add details (optional)", `submit` "Submit report", `thanks` "Thanks for letting us know. We'll review it.", `already_reported` "You already reported this.", `block_title` "Block @{username}?", `block_message` "They won't be able to find your profile, posts or message you. They won't be notified.", `blocked` "Blocked.", `unblock` "Unblock", `unblocked` "Unblocked.", `remove_follower` "Remove follower".
- **Accept**: each entry point opens the sheet; report row appears in `reports` (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(moderation): P9-T02 report and block flows`

#### [ ] P9-T03 — Blocked accounts screen
- **Read**: §6.2 blocks row, `user_list_tile.dart`, route table `blockedAccounts`. **Files**: C `lib/features/moderation/presentation/providers/blocked_users_controller.dart`, C `lib/features/moderation/presentation/screens/blocked_accounts_screen.dart`, M `app_router.dart`, M translations (`moderation.blocked_*`).
- **Steps**: list `UserListTile`-like rows (reuse `follow/presentation/widgets/user_list_tile.dart` with trailing Unblock button) → unblock → remove row.
- Keys: `moderation.blocked_title` "Blocked accounts", `blocked_empty` "You haven't blocked anyone.".
- **Accept**: manual QA. **Verify**: VERIFY-STD.
- **Commit**: `feat(moderation): P9-T03 blocked accounts`

#### [ ] P9-T04 — Content guidelines screen
- **Read**: §2.2 verbatim, route table `guidelines`. **Files**: C `lib/features/settings/presentation/screens/guidelines_screen.dart`, M `app_router.dart`.
- **Steps**: app bar `guidelines.title`; intro; 7 numbered items (§2.2) each with leading gold `circleCheck` icon; footer `guidelines.footer` "If you see something that breaks these guidelines, please report it." (add key).
- **Accept**: reachable from create flows and sign-up link. **Verify**: VERIFY-STD.
- **Commit**: `feat(settings): P9-T04 content guidelines screen`

#### [ ] P9-T05 — Settings screen
- **Read**: route table rows settings/editProfile/blockedAccounts/guidelines/forgotPassword, `theme_mode_controller.dart`, `profile_menu_sheet.dart`. **Files**: C `lib/features/settings/presentation/screens/settings_screen.dart`, C `lib/features/settings/presentation/widgets/{settings_section,language_sheet,theme_sheet}.dart`, M `lib/core/constants/app_constants.dart` (`privacyPolicyUrl = ''`, `termsUrl = ''` — owner fills later), M `profile_menu_sheet.dart` (Settings only; Log out moves here), M `app_router.dart`, M translations (`settings.*`).
- **Steps**: sections — Account: Edit profile, Private account switch (`ProfileController.setPrivate`), Follow requests (if private), Blocked accounts, Change password (→ `AppRoutes.forgotPassword`); App: Language (sheet ar/en → `context.setLocale`), Theme (sheet system/light/dark → `ThemeModeController.setMode`); About: Content guidelines, Privacy policy, Terms (rows hidden when URL empty; open via `launchUrl(mode: externalApplication)`), Version `x.y.z (build)` from `PackageInfo.fromPlatform()`; Log out (confirm); Delete account (P9-T06, destructive color).
- Keys: `settings.title` "Settings", `account` "Account", `app` "App", `about` "About", `language` "Language", `arabic` "العربية", `english` "English", `theme` "Theme", `theme_system` "System", `theme_light` "Light", `theme_dark` "Dark", `change_password` "Change password", `privacy` "Privacy policy", `terms` "Terms of use", `version` "Version", `logout` "Log out", `delete_account` "Delete account".
- **Accept**: switching language flips RTL instantly; theme persists after restart (manual QA). **Verify**: VERIFY-STD.
- **Commit**: `feat(settings): P9-T05 settings screen`

#### [ ] P9-T06 — Account deletion (017)
- **Read**: §6.4 delete_my_account, §6.5 paths. **Files**: C `supabase/migrations/017_account_deletion.sql`, C `lib/features/settings/domain/repositories/account_repository.dart`, C `lib/features/settings/domain/usecases/delete_account.dart`, C `lib/features/settings/data/datasources/account_remote_data_source.dart`, C `lib/features/settings/data/repositories/account_repository_impl.dart`, C `lib/features/settings/di/settings_providers.dart`, C `lib/features/settings/presentation/widgets/delete_account_dialog.dart`, M `settings_screen.dart`, M translations (`settings.delete.*`).
- **Steps**: migration + DB-STD. Data: for each bucket (`avatars`, `post-images`, `reel-videos`, `story-media`, `chat-media`) list `'{uid}'` (folders) and one level deeper, collect file paths, `remove` in batches of 100 (best-effort, log failures); then `rpc('delete_my_account')`; then `auth.signOut()`. Dialog requires typing own username exactly; progress state; done → router goes to login.
- Keys: `settings.delete.title` "Delete your account?", `message` "This permanently deletes your profile, posts, reels, stories and messages.", `type_username` "Type your username to confirm", `confirm` "Delete permanently", `deleting` "Deleting…".
- **Accept**: test account fully removed (auth user gone; owner checks Dashboard). **Verify**: VERIFY-STD + DB-STD.
- **Commit**: `feat(settings): P9-T06 account deletion`

#### [ ] P9-T07 — Polish pass (fixed checklist only)
- **Read**: P1-T09 route table (every row). **Files**: only screens failing a check (list them in the commit body). Do not create a new screen.
- **Steps** — walk the route table top to bottom. For each existing screen fix ONLY these: (1) first load shows a skeleton, not a bare spinner (lists/grids/profile); (2) empty state uses `EmptyView`; (3) errors use `ErrorView` with retry; (4) lists have pull-to-refresh where data can change; (5) scroll views dismiss the keyboard on drag; (6) content inside `SafeArea`; (7) tablet width constrained by `MaxWidthBox` on auth/settings/forms; (8) disabled buttons while submitting; (9) every `IconButton` has `tooltip: LocaleKeys...tr()`.
- **Accept**: checklist table in commit body with ✓ per screen. **Verify**: VERIFY-STD.
- **Commit**: `fix(ui): P9-T07 polish pass`

#### [ ] P9-T08 — Accessibility & RTL tests
- **Read**: `post_card.dart`, `profile_header.dart`, §4. **Files**: C `test/features/post/presentation/post_card_test.dart`, C `test/features/profile/presentation/profile_header_test.dart`.
- **Steps**: pump `PostCard` with a fake `Post` (media url null → placeholder) and `ProfileHeader` with a fake `Profile`, in `ar` and `en`, wrapped in `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(1.3)))`; assert no overflow exceptions (`tester.takeException()` is null) and that in `ar` the username `Text` is right-aligned within the header (`tester.getTopRight(find.text(...)).dx > width / 2`).
- **Accept**: tests pass. **Verify**: VERIFY-STD.
- **Commit**: `test(ui): P9-T08 accessibility and RTL tests`

#### [ ] P9-T09 — Remove Firebase and all legacy leftovers
- **Read**: legacy inventory, `pubspec.yaml`. **Files**: M `pubspec.yaml` (remove `cloud_firestore`, `firebase_auth`, `firebase_core`, `firebase_storage`, `date_format`, `flutter_screenutil`, `cupertino_icons`; remove `- images/` asset line); D P9-T09 inventory row; D `ios/Runner/GoogleService-Info.plist` if it exists; M `analysis_options.yaml` (remove remaining LEGACY lines and the platform folder excludes for deleted folders); M `.metadata` only if Flutter tooling rewrites it.
- **Steps**: `git rm -r` listed paths; `fvm flutter pub get`; `grep -rni "firebase\|instagram" lib android/app ios/Runner pubspec.yaml` → only allowed hit: none (if `instagram` appears in non-code docs, ignore; in code → STOP and report). `cd ios && pod install` (OWNER-ACTION if CocoaPods unavailable).
- **Accept**: grep clean; analyze 0; tests pass. **Verify**: VERIFY-STD + both phase-end builds.
- **Commit**: `chore(repo): P9-T09 remove firebase and legacy code`

#### [ ] P9-T10 — Test completeness pass
- **Read**: §3.4 T16, `test/features/**`. **Files**: C missing tests only, under `test/features/<feature>/data/` and `test/features/<feature>/domain/`.
- **Steps**: for each feature (auth, profile, post, comments, story, reel, follow, explore, chat, notifications, moderation, settings) `ls` its data and domain test files. If a layer has zero tests, add one file using the T16 pattern and an existing use case from that feature. Do not add a test for a use case that does not exist. Run `fvm flutter test --coverage`. Coverage percent is recorded in §10; there is no minimum percent.
- **Accept**: table in commit body (feature → test files). All pass. **Verify**: VERIFY-STD.
- **Commit**: `test(core): P9-T10 test completeness`

#### [ ] P9-T11 — Performance checks
- **Read**: `lib/core/widgets/app_network_image.dart`, `lib/core/media/video_controller_pool.dart`. **Files**: only files failing a check.
- **Steps**: (1) `grep -rn "CachedNetworkImage(" lib | grep -v app_network_image.dart` → empty; (2) `grep -rn "VideoPlayerController\." lib/features | grep -v -e create_reel -e create_story` → empty (players come from the pool); (3) every `ListView`/grid uses builder/paged variants (no `children:` with mapped lists > 20 items); (4) `const` where analyzer suggests (already enforced). OWNER-ACTION (optional): `fvm flutter run --profile --dart-define-from-file=env/dev.json` and scroll feed/reels in DevTools; report jank.
- **Accept**: greps clean. **Verify**: VERIFY-STD.
- **Commit**: `perf(core): P9-T11 performance checks`

#### [ ] P9-T12 — Android release prep
- **Read**: `android/app/build.gradle.kts`, `.gitignore`. **Files**: C `android/app/proguard-rules.pro` if missing (content: `# Halalgram R8 rules` + rules from `build/app/outputs/mapping/release/missing_rules.txt` if the build asks); C `env/prod.json` (OWNER, gitignored).
- **Steps**: OWNER-ACTION: create upload keystore (`keytool -genkey -v -keystore ~/halalgram-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`) and `android/key.properties` (`storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile=/Users/<owner>/halalgram-upload.jks`) — gitignored, executor never reads it. Executor: `fvm flutter build appbundle --release --dart-define-from-file=env/prod.json`.
- **Accept**: `build/app/outputs/bundle/release/app-release.aab` exists. **Verify**: command above.
- **Commit**: `chore(android): P9-T12 release build configuration`

#### [ ] P9-T13 — iOS release prep
- **Read**: `ios/Runner/Info.plist`. **Files**: none by executor unless the build demands (log it).
- **Steps**: OWNER-ACTION: in Xcode set Team + signing for `com.halalgram.app`, add `PrivacyInfo.xcprivacy` (data collected: email, user content, photos/videos; no tracking) to Runner target, and optional `InfoPlist.strings` (ar) with `CFBundleDisplayName = "حلال كرام"`. Executor (if signing available): `fvm flutter build ipa --release --dart-define-from-file=env/prod.json`.
- **Accept**: owner confirms archive builds. **Verify**: command above.
- **Commit**: `chore(ios): P9-T13 release prep notes` (commit only this plan's log update if no files changed)

#### [ ] P9-T14 — Docs + final QA
- **Read**: §8.1, `SUPABASE_SETUP.md`, `README.md`. **Files**: M `SUPABASE_SETUP.md` (rewrite: cloud-only flow, env files, `--dart-define-from-file`, migrations 001–017, email templates with `{{ .Token }}`, smoke test, never service_role), M `README.md` (rewrite: Halalgram summary, requirements fvm 3.47.2, run/build commands, folder overview, link to this plan), M `SCHEMA_DESIGN_DECISIONS.md` (append 017 note).
- **Steps**: write docs; run the full §8 manual QA checklist on Android + iOS (OWNER runs on devices; executor records results in §10).
- **Accept**: all QA items ticked or logged as issues. **Verify**: VERIFY-STD + both builds.
- **Commit**: `docs(repo): P9-T14 docs and final QA`

#### [ ] P9-T15 — CI workflow
- **Read**: §1.3 VERIFY-STD, `.fvmrc`. **Files**: C `.github/workflows/halalgram_ci.yml`, C `env/ci.json`.
- **Steps**:
  1. `env/ci.json` contains only `{"SUPABASE_URL":"https://ci.supabase.co","SUPABASE_PUBLISHABLE_KEY":"ci-placeholder"}`. It is a fake public project URL so analyze/tests can compile. It is allowed to be committed. Do not put a real key here.
  2. Workflow `on: [push, pull_request]`, `ubuntu-latest`. Steps: checkout; `subosito/flutter-action` with `flutter-version: 3.47.2` and `channel: stable`; `flutter pub get`; `dart run easy_localization:generate -S assets/translations -O lib/core/l10n -o locale_keys.g.dart -f keys`; `dart run build_runner build -d`; `dart format --set-exit-if-changed lib test`; `flutter analyze`; `flutter test --dart-define-from-file=env/ci.json`.
  3. No Android/iOS build in CI. No secrets. No `supabase` CLI.
- **Accept**: YAML parses (`python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/halalgram_ci.yml'))"`). `git check-ignore env/ci.json` prints nothing.
- **Verify**: the accept commands. A failing local `flutter` in this workflow file is not a reason to change the versions.
- **Commit**: `ci(repo): P9-T15 analyze and test workflow`

---

## 8. Definition of Done (per phase) + manual QA

Every phase DoD also includes: VERIFY-STD green (analyze `No issues found!`, `check_rules.sh` `OK`, all tests pass); both phase-end builds succeed (or logged OWNER-ACTION when no JDK/Xcode); `git status` clean; all phase tasks `[x]` with §10 rows. Tick the boxes below in the phase's last task commit.

**Phase 0 — Safety & setup**
- [ ] Branch `halalgram/v1` exists; first commit contains the pre-plan working tree.
- [ ] `git check-ignore env/dev.json android/key.properties` prints both paths.
- [ ] `grep -rn "flutter_instagram_clone" lib test pubspec.yaml` → empty; Android `applicationId`/iOS bundle id = `com.halalgram.app`.
- [ ] `.cursor/rules/*.mdc` (3) and `AGENTS.md` match §9 byte-for-byte.
- [ ] Owner confirmed Supabase project linked; `supabase migration list` shows 001–003 remote.
- [ ] App launches (legacy UI still works).

**Phase 1 — Foundation**
- [ ] App opens to splash → login placeholder / shell with 5 tabs (placeholders) in Arabic RTL by default.
- [ ] Language switch (debug toggle or device locale) flips to English LTR; theme follows system light/dark.
- [ ] Cairo renders (no fallback font) in both languages; no `google_fonts` network calls.
- [ ] Launcher icon + native splash show the Halalgram mark (no Instagram assets).
- [ ] `lib/core/**` contains theme, router, l10n, network, di, widgets per §3.1.

**Phase 2 — Database**
- [ ] `supabase migration list` shows 001–016 remote.
- [ ] `supabase/seed/qa_seed.sql` exists and was not executed by the executor.
- [ ] `rls_smoke.sql` run by owner (or MCP) ends with all ASSERTs passing then `ROLLBACK`.
- [ ] Security advisor (Dashboard → Advisors) shows no "RLS disabled" errors for public tables.

**Phase 3 — Auth & profile**
- [ ] Sign up (OTP email) → onboarding (username) → home; login; logout; password reset by OTP code.
- [ ] Own profile shows counters, edit profile (avatar upload, bio, full name), private toggle saved.
- [ ] Other user's profile opens from a deep route; legacy auth/profile files deleted.

**Phase 4 — Posts, feed, comments**
- [ ] Create post with 1–10 images + caption; appears at top of own feed and profile grid.
- [ ] Like (double-tap + button), save, comments with replies and comment likes; counters update.
- [ ] Hijri date shown on posts; occasion banner shows on matching dates (test with debug date override if available, else unit test).
- [ ] Feed paginates (scroll past 20 posts with seed data or owner test).

**Phase 5 — Stories & highlights**
- [ ] Add image/video story; ring shows on home tray and profile; viewer progresses, pauses on hold.
- [ ] Viewers list for own story; story expires after 24 h (check `expires_at`); highlight create/edit/view.

**Phase 6 — Reels**
- [ ] Pick video ≤ `MediaLimits.reelMaxDuration` (90 s), thumbnail generated, upload; reels tab plays one at a time, preloads next.
- [ ] Mute toggle (original audio only — no music UI anywhere); like/comment/share on reels.

**Phase 7 — Explore, search, follow**
- [ ] Explore quilted grid paginates; search by username/full name; recent searches persist.
- [ ] Follow public → Following; follow private → Requested → owner accepts → posts visible.
- [ ] Followers/following lists; remove follower; follow requests screen.

**Phase 8 — Chat & notifications**
- [ ] Two accounts exchange text, image, and shared-post messages live (no refresh).
- [ ] Unsend works; images load via signed URLs; inbox order updates.
- [ ] Notifications for like/comment/reply/follow/request/accept appear; badges update in realtime and on resume.

**Phase 9 — Moderation, settings, release**
- [ ] Report from post, reel, comment, profile, story, message; duplicate report shows "already reported".
- [ ] Block hides both users from each other everywhere (profile, feed, search, chat); unblock restores.
- [ ] Settings: language, theme, private, blocked accounts, guidelines, version, logout, delete account.
- [ ] `grep -rni firebase lib android ios pubspec.yaml` → empty; no LEGACY excludes in `analysis_options.yaml`.
- [ ] Release `.aab` built; iOS archive confirmed by owner.
- [ ] `.github/workflows/halalgram_ci.yml` runs analyze and test with `env/ci.json` and no secrets.

### 8.1 Manual QA checklist (owner, real devices; run at end of P4, P6, P8, P9)

Setup: 3 test accounts — **A** (private), **B** (public), **C** (public). Run each item in **ar + light** and **en + dark** (minimum); tick both columns.

| # | Scenario | ar/light | en/dark |
|---|----------|----------|---------|
| 1 | Fresh install → splash → sign up B with OTP → onboarding → home | [ ] | [ ] |
| 2 | Logout / login; wrong password shows localized error | [ ] | [ ] |
| 3 | Password reset with OTP code | [ ] | [ ] |
| 4 | All screens mirror correctly in RTL (back arrows, swipes, paddings, bottom nav order) | [ ] | [ ] |
| 5 | System text size at largest: no overflow on feed, profile, chat | [ ] | [ ] |
| 6 | B creates 3-image post; carousel dots; caption "more"; Hijri date | [ ] | [ ] |
| 7 | C likes, comments, replies on B's post; B gets notifications | [ ] | [ ] |
| 8 | B adds image + video story; C views; B sees viewer list | [ ] | [ ] |
| 9 | B uploads reel; reels feed autoplay/pause on scroll; mute toggle | [ ] | [ ] |
| 10 | C follows A (private) → requested; A accepts; C now sees A's posts | [ ] | [ ] |
| 11 | Before acceptance, C cannot see A's posts/stories/reels anywhere (profile, explore, search grid) | [ ] | [ ] |
| 12 | B ↔ C chat realtime (text, image, shared post); unsend | [ ] | [ ] |
| 13 | Badges on heart/send icons update without restart; clear after opening | [ ] | [ ] |
| 14 | C reports B's post (reason "Contains music"); repeat → "already reported" | [ ] | [ ] |
| 15 | B blocks C → C can't find B in search, can't open B's profile/chat; B unblocks | [ ] | [ ] |
| 16 | Airplane mode: error views with retry; recover when back online | [ ] | [ ] |
| 17 | Settings: switch language/theme persists after app restart | [ ] | [ ] |
| 18 | Delete a throwaway account (type username) → returns to login; cannot log in again | [ ] | [ ] |
| 19 | No Instagram logo/wordmark/gradient/music UI anywhere | [ ] | [ ] |

---

## 9. AI rule files (exact contents — written by P0-T03)

### 9.1 `.cursor/rules/halalgram-core.mdc`

````markdown
---
description: Halalgram core executor rules (always on)
alwaysApply: true
---

# Halalgram — core rules

Source of truth: `docs/HALALGRAM_PLAN.md`. Contract = §1. Tasks = §7.

## Workflow
- Do exactly ONE task ID at a time, in §7 order. Read only the files it lists.
- Create/modify/delete only the files listed in the task.
- After the task: run VERIFY-STD (§1.3); tick the task `[x]`; add a §10 row; commit with the task's exact message.
- STOP and report (task ID, blocker, exact error) when: a command fails twice, an API differs from the plan, a spec is ambiguous, a file/package is not listed, or an OWNER-ACTION is reached.

## Commands
- Always `fvm flutter ...` / `fvm dart ...`. Never plain `flutter` / `dart`.
- Run with `--dart-define-from-file=env/dev.json`.
- Never `supabase db reset`. `supabase db push` only in the task that creates the migration.

## Hard bans
- No new/removed/upgraded packages outside §5.
- No `service_role` key, DB password, or secrets in code, logs, or commits. Never commit or print `env/dev.json`, `env/prod.json`, or `android/key.properties`. `env/example.json` and `env/ci.json` are the only env files that may be committed.
- Never edit migrations 001–003 or any already-pushed migration.
- No hardcoded user-visible strings: use `LocaleKeys.x.tr()` and add keys to BOTH `ar.json` and `en.json`.
- No hardcoded colors/sizes/spacing/durations: use tokens in `lib/core/theme/` (§4). Only `Colors.transparent` is allowed.
- No `left/right` layout: use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`.
- No `print` / `debugPrint`: use `loggerProvider`.
- No Instagram logo, wordmark, gradients, or icon assets. No music features.
- No unrelated refactors, renames, or reformatting.

## Architecture (details §3)
- Feature-first Clean Architecture: `lib/features/<f>/{domain,data,presentation,di}`.
- `domain/` is pure Dart (no Flutter, no Supabase).
- `presentation/` never imports `data/`; it uses providers from `di/`.
- `package:supabase_flutter` only in `bootstrap.dart`, `core/network`, `core/di`, `features/*/data`, `features/*/di`.
- Riverpod generator (`@riverpod`), freezed, fpdart `FutureEither`, go_router. Copy §3.4 templates exactly.

## Reporting
- Final report ≤10 lines: task ID, files changed, verify results, commit hash.
````

### 9.2 `.cursor/rules/halalgram-features.mdc`

````markdown
---
description: Layer rules for Halalgram feature code
globs: lib/features/**
alwaysApply: false
---

# Feature layer rules (plan §3.2–§3.4)

- `domain/entities`: freezed classes, no JSON, no Flutter imports.
- `domain/repositories`: abstract interface classes returning `FutureEither<T>` or `Stream<T>`.
- `domain/usecases`: one public `call` method; validation returns `Left(ValidationFailure(...))`.
- `data/models`: freezed + json_serializable (`field_rename: snake` via build.yaml); `toEntity(...)` maps to domain.
- `data/datasources`: only place that talks to Supabase; throws; never returns Either.
- `data/repositories`: wraps datasource calls with `guard(...)` (T3) → `FutureEither`.
- `di/<f>_providers.dart`: keepAlive providers for datasource, repository, and each use case (`<useCaseCamel>Provider`).
- `presentation/providers`: `@riverpod` notifiers; read use cases from `di/`; never import `data/`.
- `presentation/screens|widgets`: tokens from `lib/core/theme`, strings from `LocaleKeys`, directional layout only.
- Paginated lists use `cursorPagingController` (T6) + `PagingListener`; images use `AppNetworkImage` only.
- Cross-feature imports allowed only for another feature's `domain/` entities and `di/` providers.
````

### 9.3 `.cursor/rules/halalgram-migrations.mdc`

````markdown
---
description: Rules for Supabase SQL migrations
globs: supabase/migrations/**
alwaysApply: false
---

# Migration rules (plan §6)

- Never edit 001–003 or any migration already shown as remote in `supabase migration list`.
- File names are fixed by §6.7. Create only the file named in the current task.
- Follow §6.0 conventions exactly: header comment, uuid PKs `DEFAULT gen_random_uuid()`, `TIMESTAMPTZ NOT NULL DEFAULT now()`, FKs `ON DELETE CASCADE`, indexes as listed in §6.1.
- Every new table: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` plus the exact policies from §6.2 (`TO authenticated`, `(select auth.uid())`).
- Functions: `SET search_path = public`; `SECURITY DEFINER` only where §6.4 says, and then check `auth.uid()` inside.
- After each function: `REVOKE ALL ... FROM PUBLIC, anon; GRANT EXECUTE ... TO authenticated;`.
- Never use `gen_random_bytes`; use `substr(md5(random()::text), 1, 6)`.
- Push with `supabase db push`, then confirm with `supabase migration list`. Never `supabase db reset`.
- Never put secrets, emails, or real user data in SQL files.
````

### 9.4 `AGENTS.md` (ROOT)

````markdown
# AGENTS.md — Halalgram

This repository is executed task-by-task from `docs/HALALGRAM_PLAN.md`.
Read §1 (EXECUTOR CONTRACT) of that file before doing anything.

## Loop
1. Open `docs/HALALGRAM_PLAN.md` §7; pick the first unchecked task whose dependencies are done.
2. Read only that task block, the plan sections it cites, and the files it lists.
3. Change only the listed files. Follow the §3.4 templates and §4 tokens exactly.
4. Run VERIFY-STD (§1.3) until green.
5. Tick `[x]`, add a §10 Progress log row, commit with the exact task message.

## MUST
- Use `fvm flutter` / `fvm dart` for every command.
- Localize every string in both `ar.json` and `en.json`.
- Use design tokens and directional layout (RTL-first).
- STOP and report on: repeated failure, API mismatch, ambiguity, unlisted file/package, OWNER-ACTION.

## MUST NOT
- Add/remove/upgrade packages outside plan §5.
- Use the Supabase `service_role` key or any secret; commit or print `env/dev.json`, `env/prod.json`, or `android/key.properties`.
- Edit migrations 001–003 or any pushed migration; run `supabase db reset`.
- Import `supabase_flutter` outside data/di/core network/bootstrap; import `data/` from presentation/domain.
- Use Instagram branding or add music features.
- Refactor, rename, or reformat code outside the task.

## Stack
Flutter 3.47.2 (fvm), Riverpod 3 + generator, go_router, freezed, fpdart, easy_localization (ar default, en), Supabase (cloud). Android + iOS only.
````

---

## 10. Progress log

| date | task id | status | notes |
|------|---------|--------|-------|
| 2026-10-17 | P0-T01 | done | Snapshot committed on branch halalgram/v1 |
| 2026-10-17 | P0-T02 | done | Ignore env, keystores, and supabase temp |
| 2026-10-17 | P0-T03 | done | Added three Cursor rules and AGENTS.md |
| 2026-10-17 | P0-T04 | done | Renamed Dart package to halalgram; 0 errors |
| 2026-10-17 | P0-T05 | blocked | Build failed twice; owner must reinstall NDK 28.2.13676358 through Android Studio SDK Manager |

| 2026-10-28 | P0-T05 | done | Identity checks passed; NDK installed automatically; debug APK built successfully |

---

## 11. Known risks & decisions

**Unverified facts (executor: STOP if reality differs; do not improvise)**
1. **Android build never ran during planning** — the planning shell had no Java runtime. AGP 9.1 + Kotlin 2.4 compatibility of every plugin (image_cropper, photo_manager, fc_native_video_thumbnail, video_player, permission_handler) is assumed. If a plugin fails on AGP 9 → STOP and report the Gradle error; do not downgrade AGP.
2. **iOS build never ran during planning**; CocoaPods availability unknown.
3. **`flutter_staggered_grid_view ^0.7.0`** was not resolved together with the rest of the set (probe command was not run). If `pub get` fails on it → STOP; owner-approved fallback is a plain `PagedSliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3)`.
4. APIs assumed but not compiled in the probe: `fc_native_video_thumbnail` (`getVideoThumbnail(srcFile:, destFile:, width:, height:, format:, quality:)`), `share_plus` 13 (`SharePlus.instance.share(ShareParams(text:))`), `image_cropper` 13 (`ImageCropper().cropImage(sourcePath:, uiSettings:)`), `hijri` `hijriToGregorian` instance method, Lucide names `squarePen`/`circleCheck`. Mismatch → STOP (contract §1.1 #17).
5. easy_localization Arabic plural forms (`zero/one/two/few/many/other`) — keys for counters must define all six in `ar.json`; verify rendering with counts 0, 1, 2, 3, 11, 100.
6. Supabase pieces not verified against the live project: inserting into `auth.users` in `rls_smoke.sql` (may need owner to run as `postgres` in SQL Editor); `delete_my_account` (security definer deleting `auth.users`) requires the function owner `postgres` to have that privilege — if it fails, fallback is an OWNER-approved Edge Function (new task).
7. The 003 line `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY` fails on hosted Supabase (not table owner). P0-T09 removes it ONLY if 001–003 were never pushed; otherwise owner decides.

**Accepted product/tech decisions**
8. Public buckets (`avatars`, `post-images`, `reel-videos`, `story-media`): media of private accounts is not listed to non-followers but reachable by direct URL. Chat media is private with signed URLs. Revisit (signed URLs everywhere) after v1.
9. Hijri dates use Umm al-Qura tables (`hijri` package) and may differ ±1 day from local moon sighting; occasion banners use the same calendar.
10. `story_view` is LTR-only → wrapped in `Directionality(ltr)`; in Arabic, tap-left still means "previous".
11. No push notifications in v1 (realtime + on-resume refresh only). FCM would reintroduce Firebase; a future option is OneSignal or Supabase + APNs/FCM via Edge Functions.
12. No video compression in v1: reels/stories capped by duration (`MediaLimits.reelMaxDuration` 90 s / `storyVideoMaxDuration` 30 s) and file size (`MediaLimits.*MaxBytes`).
13. Password reset and email confirmation use 6-digit OTP codes (no deep links); owner must edit Supabase email templates to include `{{ .Token }}` (P0-T09 step 1f).
14. `custom_lint` is not used (incompatible with freezed 4's analyzer); `riverpod_lint` runs as an analysis_server plugin.
15. Supabase CLI writes to `~/.supabase`; sandboxed agents must run it with full permissions.
16. Lint `unnecessary_type_name_in_constructor` and `sort_pub_dependencies` are disabled (freezed compatibility / ordering noise).

**Reference repos (patterns only; check LICENSE before copying anything — contract §1.2 #11)**
- Supabase Flutter user management example: https://github.com/supabase/supabase/tree/master/examples/user-management/flutter-user-management
- Supabase community Flutter chat: https://github.com/supabase-community/flutter-chat
- Riverpod examples: https://github.com/rrousselGit/riverpod/tree/master/examples
- Starter architecture (Riverpod + go_router): https://github.com/bizz84/starter_architecture_flutter_firebase
- Clean architecture TDD reference: https://github.com/ResoCoder/flutter-tdd-clean-architecture-course
