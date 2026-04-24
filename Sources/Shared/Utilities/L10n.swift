import Foundation

enum L10n {
    static let appTitle = "iOSBili"

    static let tabHome = "\u{9996}\u{9875}"
    static let tabSearch = "\u{641c}\u{7d22}"
    static let tabDynamic = "\u{52a8}\u{6001}"
    static let tabLibrary = "\u{7247}\u{5e93}"
    static let tabProfile = "\u{6211}\u{7684}"

    static let feedPicker = "\u{5185}\u{5bb9}"
    static let feedRecommended = "\u{63a8}\u{8350}"
    static let feedHot = "\u{70ed}\u{95e8}"
    static let homeLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{9996}\u{9875}\u{5185}\u{5bb9}..."
    static let homeEmptyTitle = "\u{9996}\u{9875}\u{6682}\u{65f6}\u{6ca1}\u{6709}\u{5185}\u{5bb9}"
    static let homeEmptySubtitle = "\u{4e0b}\u{62c9}\u{5237}\u{65b0}\u{6216}\u{7a0d}\u{540e}\u{518d}\u{8bd5}\u{3002}"
    static let homeLoadAction = "\u{52a0}\u{8f7d}\u{9996}\u{9875}\u{5185}\u{5bb9}"
    static let homeRecommendedLoadFailed = "\u{63a8}\u{8350}\u{5185}\u{5bb9}\u{6682}\u{65f6}\u{52a0}\u{8f7d}\u{5931}\u{8d25}\u{3002}"
    static let homeHotLoadFailed = "\u{70ed}\u{95e8}\u{5185}\u{5bb9}\u{6682}\u{65f6}\u{52a0}\u{8f7d}\u{5931}\u{8d25}\u{3002}"
    static let homeBangumiLoadFailed = "\u{756a}\u{5267}\u{699c}\u{5355}\u{6682}\u{65f6}\u{52a0}\u{8f7d}\u{5931}\u{8d25}\u{3002}"
    static let loadMore = "\u{52a0}\u{8f7d}\u{66f4}\u{591a}"
    static let loadingMore = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{66f4}\u{591a}..."
    static let searchPlaceholderDefault = "\u{641c}\u{7d22}\u{89c6}\u{9891}\u{3001}UP \u{4e3b}\u{3001}\u{756a}\u{5267}"

    static let webLoginTitle = "\u{767b}\u{5f55}\u{8fc1}\u{79fb}"
    static let qrLoginTabTitle = "\u{626b}\u{7801}\u{767b}\u{5f55}"
    static let browserLoginTabTitle = "\u{7f51}\u{9875}\u{767b}\u{5f55}"
    static let close = "\u{5173}\u{95ed}"
    static let save = "\u{4fdd}\u{5b58}"
    static let `import` = "\u{5bfc}\u{5165}"
    static let webLoginHint = "\u{8bf7}\u{5148}\u{5728}\u{7f51}\u{9875}\u{4e2d}\u{5b8c}\u{6210}\u{767b}\u{5f55}\u{ff0c}\u{7136}\u{540e}\u{70b9}\u{51fb}\u{53f3}\u{4e0a}\u{89d2}\u{5bfc}\u{5165} Cookie\u{3002}"
    static let webLoginMissingCookie = "\u{6682}\u{672a}\u{68c0}\u{6d4b}\u{5230}\u{767b}\u{5f55} Cookie\u{ff0c}\u{8bf7}\u{786e}\u{8ba4}\u{7f51}\u{9875}\u{767b}\u{5f55}\u{5df2}\u{5b8c}\u{6210}\u{3002}"
    static let qrLoginHint = "\u{8bf7}\u{4f7f}\u{7528} bilibili \u{5b98}\u{65b9} App \u{626b}\u{63cf}\u{4e0b}\u{65b9}\u{4e8c}\u{7ef4}\u{7801}\u{5b8c}\u{6210}\u{767b}\u{5f55}\u{3002}"
    static let qrLoginGenerating = "\u{6b63}\u{5728}\u{751f}\u{6210}\u{626b}\u{7801}\u{767b}\u{5f55}\u{4e8c}\u{7ef4}\u{7801}..."
    static let qrLoginRefresh = "\u{5237}\u{65b0}\u{4e8c}\u{7ef4}\u{7801}"
    static let qrLoginStatusWaiting = "\u{7b49}\u{5f85}\u{626b}\u{7801}"
    static let qrLoginStatusScanned = "\u{5df2}\u{626b}\u{7801}\u{ff0c}\u{7b49}\u{5f85}\u{5728} App \u{5185}\u{786e}\u{8ba4}"
    static let qrLoginStatusSuccess = "\u{626b}\u{7801}\u{6210}\u{529f}\u{ff0c}\u{6b63}\u{5728}\u{5bfc}\u{5165}\u{767b}\u{5f55}\u{72b6}\u{6001}..."
    static let qrLoginExpired = "\u{4e8c}\u{7ef4}\u{7801}\u{5df2}\u{8fc7}\u{671f}\u{ff0c}\u{8bf7}\u{5237}\u{65b0}\u{540e}\u{91cd}\u{8bd5}\u{3002}"
    static let qrLoginBackgroundActive = "\u{5e94}\u{7528}\u{5df2}\u{5207}\u{5230}\u{540e}\u{53f0}\u{ff0c}\u{5c06}\u{5728} iOS \u{5141}\u{8bb8}\u{7684}\u{80cc}\u{666f}\u{65f6}\u{95f4}\u{5185}\u{7ee7}\u{7eed}\u{8f6e}\u{8be2}\u{3002}"
    static let qrLoginBackgroundExpired = "\u{540e}\u{53f0}\u{8f6e}\u{8be2}\u{65f6}\u{95f4}\u{5df2}\u{7528}\u{5c3d}\u{ff0c}\u{8fd4}\u{56de}\u{524d}\u{53f0}\u{540e}\u{4f1a}\u{81ea}\u{52a8}\u{7ee7}\u{7eed}\u{3002}"
    static let qrLoginOpenInAppHint = "\u{5982}\u{679c}\u{5f53}\u{524d}\u{8bbe}\u{5907}\u{4e0a}\u{5df2}\u{5b89}\u{88c5} bilibili \u{5b98}\u{65b9} App\u{ff0c}\u{53ef}\u{4ee5}\u{622a}\u{56fe}\u{6216}\u{7528}\u{5176}\u{4ed6}\u{5df2}\u{767b}\u{5f55}\u{8bbe}\u{5907}\u{626b}\u{63cf}\u{3002}"
    static let qrLoginCountdownPrefix = "\u{5269}\u{4f59}\u{6709}\u{6548}\u{65f6}\u{95f4}"
    static let qrLoginCookieMissing = "\u{626b}\u{7801}\u{6210}\u{529f}\u{4f46}\u{672a}\u{62ff}\u{5230} Cookie \u{4fe1}\u{606f}\u{ff0c}\u{8bf7}\u{91cd}\u{65b0}\u{5237}\u{65b0}\u{4e8c}\u{7ef4}\u{7801}\u{3002}"

    static let historyTitle = "\u{5386}\u{53f2}\u{8bb0}\u{5f55}"
    static let historyLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{5386}\u{53f2}\u{8bb0}\u{5f55}..."
    static let historyEmptyTitle = "\u{8fd8}\u{6ca1}\u{6709}\u{89c2}\u{770b}\u{5386}\u{53f2}"
    static let historyEmptySubtitle = "\u{767b}\u{5f55}\u{6001}\u{4e0b}\u{89c2}\u{770b}\u{8fc7}\u{7684}\u{89c6}\u{9891}\u{4f1a}\u{663e}\u{793a}\u{5728}\u{8fd9}\u{91cc}\u{3002}"
    static let historyLoadAction = "\u{52a0}\u{8f7d}\u{5386}\u{53f2}\u{8bb0}\u{5f55}"
    static let historyDeleteConfirmTitle = "\u{5220}\u{9664}\u{8fd9}\u{6761}\u{5386}\u{53f2}\u{8bb0}\u{5f55}\u{ff1f}"
    static let historyDeleteConfirmMessage = "\u{5220}\u{9664}\u{540e}\u{5c06}\u{4e0d}\u{518d}\u{51fa}\u{73b0}\u{5728}\u{8fd9}\u{4e2a}\u{5217}\u{8868}\u{4e2d}\u{3002}"
    static let historyClearConfirmTitle = "\u{6e05}\u{7a7a}\u{5168}\u{90e8}\u{5386}\u{53f2}\u{8bb0}\u{5f55}\u{ff1f}"
    static let historyClearConfirmMessage = "\u{8fd9}\u{4f1a}\u{6e05}\u{7a7a}\u{5f53}\u{524d}\u{8d26}\u{53f7}\u{7684}\u{89c2}\u{770b}\u{5386}\u{53f2}\u{3002}"
    static let historyRemoved = "\u{5df2}\u{5220}\u{9664}\u{8fd9}\u{6761}\u{5386}\u{53f2}\u{8bb0}\u{5f55}\u{3002}"
    static let historyCleared = "\u{5df2}\u{6e05}\u{7a7a}\u{5168}\u{90e8}\u{5386}\u{53f2}\u{8bb0}\u{5f55}\u{3002}"

    static let watchLaterTitle = "\u{7a0d}\u{540e}\u{518d}\u{770b}"
    static let watchLaterLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{7a0d}\u{540e}\u{518d}\u{770b}..."
    static let watchLaterEmptyTitle = "\u{7a0d}\u{540e}\u{518d}\u{770b}\u{8fd8}\u{662f}\u{7a7a}\u{7684}"
    static let watchLaterEmptySubtitle = "\u{53ef}\u{4ee5}\u{5728}\u{89c6}\u{9891}\u{8be6}\u{60c5}\u{9875}\u{628a}\u{5185}\u{5bb9}\u{52a0}\u{5165}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{3002}"
    static let watchLaterLoadAction = "\u{52a0}\u{8f7d}\u{7a0d}\u{540e}\u{518d}\u{770b}"
    static let remove = "\u{79fb}\u{9664}"
    static let delete = "\u{5220}\u{9664}"
    static let cancel = "\u{53d6}\u{6d88}"
    static let clearAll = "\u{5168}\u{90e8}\u{6e05}\u{7a7a}"
    static let watchLaterClearConfirmTitle = "\u{6e05}\u{7a7a}\u{5168}\u{90e8}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{ff1f}"
    static let watchLaterClearConfirmMessage = "\u{8fd9}\u{4f1a}\u{79fb}\u{9664}\u{5f53}\u{524d}\u{8d26}\u{53f7}\u{4e2d}\u{7684}\u{5168}\u{90e8}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{5185}\u{5bb9}\u{3002}"
    static let watchLaterCleared = "\u{5df2}\u{6e05}\u{7a7a}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{5217}\u{8868}\u{3002}"
    static let watchLaterRemoved = "\u{5df2}\u{4ece}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{4e2d}\u{79fb}\u{9664}\u{3002}"

    static let favoritesTitle = "\u{6536}\u{85cf}\u{5939}"
    static let favoritesLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{6536}\u{85cf}\u{5185}\u{5bb9}..."
    static let favoritesEmptyTitle = "\u{8fd9}\u{4e2a}\u{6536}\u{85cf}\u{5939}\u{8fd8}\u{662f}\u{7a7a}\u{7684}"
    static let favoritesEmptySubtitle = "\u{53ef}\u{4ee5}\u{5728}\u{89c6}\u{9891}\u{8be6}\u{60c5}\u{9875}\u{7ee7}\u{7eed}\u{6dfb}\u{52a0}\u{6536}\u{85cf}\u{3002}"
    static let favoritesLoadAction = "\u{52a0}\u{8f7d}\u{6536}\u{85cf}\u{5185}\u{5bb9}"
    static let removeFromFavorite = "\u{79fb}\u{51fa}\u{6536}\u{85cf}\u{5939}"
    static let favoritePickerTitle = "\u{9009}\u{62e9}\u{6536}\u{85cf}\u{5939}"
    static let favoritePickerLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{6536}\u{85cf}\u{5939}..."
    static let favoritePickerEmpty = "\u{8fd8}\u{6ca1}\u{6709}\u{53ef}\u{9009}\u{6536}\u{85cf}\u{5939}\u{ff0c}\u{8bf7}\u{5148}\u{5728}\u{201c}\u{6211}\u{7684}\u{201d}\u{9875}\u{786e}\u{8ba4}\u{6536}\u{85cf}\u{5939}\u{662f}\u{5426}\u{53ef}\u{89c1}\u{3002}"
    static let favoritePickerLoadAction = "\u{52a0}\u{8f7d}\u{6536}\u{85cf}\u{5939}\u{5217}\u{8868}"

    static let profileLoading = "\u{6b63}\u{5728}\u{540c}\u{6b65}\u{8d26}\u{53f7}\u{4fe1}\u{606f}..."
    static let profileLoadTitle = "\u{5c1a}\u{672a}\u{52a0}\u{8f7d}\u{8d26}\u{53f7}\u{4fe1}\u{606f}"
    static let profileLoadSubtitle = "\u{70b9}\u{51fb}\u{4e0b}\u{65b9}\u{6309}\u{94ae}\u{540e}\u{518d}\u{540c}\u{6b65}\u{4e2a}\u{4eba}\u{4e3b}\u{9875}\u{3001}\u{7edf}\u{8ba1}\u{548c}\u{6536}\u{85cf}\u{5939}\u{3002}"
    static let profileLoadAction = "\u{52a0}\u{8f7d}\u{8d26}\u{53f7}\u{4fe1}\u{606f}"
    static let profileSessionTitle = "\u{767b}\u{5f55}\u{4f1a}\u{8bdd}"
    static let profileSessionSubtitle = "\u{67e5}\u{770b} Cookie \u{5173}\u{952e}\u{5b57}\u{6bb5}\u{548c}\u{5f53}\u{524d}\u{540c}\u{6b65}\u{72b6}\u{6001}"
    static let notLoggedIn = "\u{672a}\u{767b}\u{5f55}"
    static let vip = "\u{5927}\u{4f1a}\u{5458}"
    static let commonActions = "\u{5e38}\u{7528}\u{529f}\u{80fd}"
    static let cookieImport = "Cookie \u{5bfc}\u{5165}"
    static let migrationInfoTitle = "\u{8fc1}\u{79fb}\u{8bf4}\u{660e}"
    static let migrationInfoText = "\u{5f53}\u{524d}\u{7248}\u{672c}\u{5df2}\u{805a}\u{7126}\u{5728}\u{8d26}\u{53f7}\u{767b}\u{5f55}\u{3001}\u{8fdc}\u{7a0b}\u{89c2}\u{770b}\u{5386}\u{53f2}\u{548c}\u{89c6}\u{9891}\u{8be6}\u{60c5}\u{7684}\u{539f}\u{751f}\u{4f53}\u{9a8c}\u{3002}\u{767b}\u{5f55}\u{652f}\u{6301}\u{626b}\u{7801}\u{3001}\u{624b}\u{52a8}\u{7c98}\u{8d34} Cookie\u{ff0c}\u{4e5f}\u{652f}\u{6301}\u{5728}\u{5185}\u{5d4c}\u{7f51}\u{9875}\u{767b}\u{5f55}\u{540e}\u{5bfc}\u{5165}\u{3002}"
    static let pasteCookieAgain = "\u{91cd}\u{65b0}\u{7c98}\u{8d34} Cookie"
    static let clearLoginState = "\u{6e05}\u{9664}\u{767b}\u{5f55}\u{6001}"
    static let loginGuideTitle = "\u{5bfc}\u{5165}\u{767b}\u{5f55}\u{6001}"
    static let loginGuideText = "\u{4e3a}\u{4e86}\u{52a0}\u{5feb} iOS \u{539f}\u{751f}\u{91cd}\u{5199}\u{ff0c}\u{8fd9}\u{4e2a}\u{7248}\u{672c}\u{5148}\u{652f}\u{6301}\u{4e09}\u{79cd}\u{767b}\u{5f55}\u{65b9}\u{5f0f}\u{ff1a}1. \u{4f7f}\u{7528} bilibili App \u{626b}\u{7801}\u{767b}\u{5f55}\u{ff1b}2. \u{76f4}\u{63a5}\u{7c98}\u{8d34}\u{6d4f}\u{89c8}\u{5668} Cookie\u{ff1b}3. \u{5728}\u{5185}\u{5d4c}\u{7f51}\u{9875}\u{767b}\u{5f55}\u{540e}\u{81ea}\u{52a8}\u{5bfc}\u{5165}\u{3002}"
    static let suggestInclude = "\u{5efa}\u{8bae}\u{81f3}\u{5c11}\u{5305}\u{542b}"
    static let cookieEditorHint = "\u{652f}\u{6301}\u{76f4}\u{63a5}\u{7c98}\u{8d34}\u{6d4f}\u{89c8}\u{5668}\u{4e2d}\u{7684}\u{6574}\u{6bb5} Cookie Header\u{3002}"
    static let cookieEditorTitle = "\u{5bfc}\u{5165} Cookie"
    static let clearCurrentLogin = "\u{6e05}\u{9664}\u{5f53}\u{524d}\u{767b}\u{5f55}\u{6001}"

    static let searchSuggestions = "\u{8054}\u{60f3}\u{8bcd}"
    static let searchResultTitle = "\u{89c6}\u{9891}\u{7ed3}\u{679c}"
    static let noSearchResultTitle = "\u{6ca1}\u{6709}\u{627e}\u{5230}\u{76f8}\u{5173}\u{89c6}\u{9891}"
    static let noSearchResultSubtitle = "\u{53ef}\u{4ee5}\u{6362}\u{4e00}\u{4e2a}\u{5173}\u{952e}\u{8bcd}\u{ff0c}\u{6216}\u{8005}\u{5237}\u{65b0}\u{5f53}\u{524d}\u{767b}\u{5f55}\u{6001}\u{540e}\u{518d}\u{8bd5}\u{3002}"
    static let searchPanelLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{641c}\u{7d22}\u{9762}\u{677f}..."
    static let searchLandingEmptyTitle = "\u{641c}\u{7d22}\u{9762}\u{677f}\u{8fd8}\u{6ca1}\u{6709}\u{51c6}\u{5907}\u{597d}"
    static let searchLandingEmptySubtitle = "\u{70ed}\u{8bcd}\u{3001}\u{63a8}\u{8350}\u{8bcd}\u{548c}\u{5386}\u{53f2}\u{8bb0}\u{5f55}\u{52a0}\u{8f7d}\u{540e}\u{4f1a}\u{663e}\u{793a}\u{5728}\u{8fd9}\u{91cc}\u{3002}"
    static let searchLandingLoadAction = "\u{52a0}\u{8f7d}\u{641c}\u{7d22}\u{9762}\u{677f}"
    static let searchHistory = "\u{641c}\u{7d22}\u{5386}\u{53f2}"
    static let clearHistory = "\u{6e05}\u{7a7a}\u{5386}\u{53f2}"
    static let hotSearch = "\u{70ed}\u{641c}"
    static let recommendKeywords = "\u{63a8}\u{8350}\u{8bcd}"
    static let searchAction = "\u{641c}\u{7d22}"
    static let searchScopeVideo = "\u{89c6}\u{9891}"
    static let searchScopeBangumi = "\u{756a}\u{5267}"
    static let searchScopeLive = "\u{76f4}\u{64ad}\u{95f4}"
    static let searchScopeUser = "\u{7528}\u{6237}"
    static let searchFilterTitle = "\u{7b5b}\u{9009}"
    static let searchFilterSubtitle = "\u{89c6}\u{9891}\u{641c}\u{7d22}\u{652f}\u{6301}\u{6392}\u{5e8f}\u{548c}\u{65f6}\u{957f}\u{7b5b}\u{9009}"
    static let searchSortDefault = "\u{9ed8}\u{8ba4}\u{6392}\u{5e8f}"
    static let searchSortPlays = "\u{64ad}\u{653e}\u{6700}\u{591a}"
    static let searchSortNewest = "\u{6700}\u{65b0}\u{53d1}\u{5e03}"
    static let searchSortDanmaku = "\u{5f39}\u{5e55}\u{6700}\u{591a}"
    static let searchSortFavorites = "\u{6536}\u{85cf}\u{6700}\u{591a}"
    static let searchSortComments = "\u{8bc4}\u{8bba}\u{6700}\u{591a}"
    static let searchDurationAll = "\u{5168}\u{90e8}\u{65f6}\u{957f}"
    static let searchDurationShort = "0-10 \u{5206}\u{949f}"
    static let searchDurationMedium = "10-30 \u{5206}\u{949f}"
    static let searchDurationLong = "30-60 \u{5206}\u{949f}"
    static let searchDurationXL = "60 \u{5206}\u{949f}+"
    static let searchUserLiveBadge = "\u{5f00}\u{64ad}\u{4e2d}"

    static let videoDetailTitle = "\u{89c6}\u{9891}\u{8be6}\u{60c5}"
    static let videoDetailLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{89c6}\u{9891}\u{8be6}\u{60c5}..."
    static let videoPages = "\u{5206}P"
    static let relatedVideos = "\u{76f8}\u{5173}\u{63a8}\u{8350}"
    static let nativePlay = "\u{539f}\u{751f}\u{64ad}\u{653e}"
    static let webPlay = "\u{7f51}\u{9875}\u{64ad}\u{653e}"
    static let addWatchLater = "\u{52a0}\u{5165}\u{7a0d}\u{540e}\u{518d}\u{770b}"
    static let addFavorite = "\u{52a0}\u{5165}\u{6536}\u{85cf}"
    static let videoFavoriteRemoveAction = "\u{53d6}\u{6d88}\u{6536}\u{85cf}"
    static let noDescription = "\u{6682}\u{65e0}\u{7b80}\u{4ecb}"
    static let missingBVID = "\u{5f53}\u{524d}\u{89c6}\u{9891}\u{7f3a}\u{5c11} bvid\u{ff0c}\u{6682}\u{65f6}\u{65e0}\u{6cd5}\u{7ee7}\u{7eed}\u{52a0}\u{8f7d}\u{8be6}\u{60c5}\u{3002}"
    static let addedWatchLater = "\u{5df2}\u{52a0}\u{5165}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{3002}"
    static let missingAidForFavorite = "\u{7f3a}\u{5c11} aid\u{ff0c}\u{6682}\u{65f6}\u{4e0d}\u{80fd}\u{6267}\u{884c}\u{6536}\u{85cf}\u{64cd}\u{4f5c}\u{3002}"
    static let videoLikeAction = "\u{70b9}\u{8d5e}"
    static let videoUnlikeAction = "\u{53d6}\u{6d88}\u{70b9}\u{8d5e}"
    static let videoCoinAction = "\u{6295}\u{5e01}"
    static let videoCoinOne = "\u{6295} 1 \u{679a}\u{786c}\u{5e01}"
    static let videoCoinTwo = "\u{6295} 2 \u{679a}\u{786c}\u{5e01}"
    static let videoInteractionLoginHint = "\u{4e92}\u{52a8}\u{64cd}\u{4f5c}\u{9700}\u{8981}\u{5148}\u{767b}\u{5f55}\u{624d}\u{80fd}\u{4f7f}\u{7528}\u{3002}"
    static let videoInteractionLoginSubtitle = "\u{767b}\u{5f55}\u{540e}\u{53ef}\u{4ee5}\u{8fdb}\u{884c}\u{70b9}\u{8d5e}\u{3001}\u{6295}\u{5e01}\u{548c}\u{6536}\u{85cf}"
    static let videoInteractionRestartSubtitle = "\u{5ffd}\u{7565}\u{8fdc}\u{7a0b}\u{65ad}\u{70b9}\u{5e76}\u{4ece}\u{5934}\u{5f00}\u{59cb}"
    static let videoCoinLimitReached = "\u{5f53}\u{524d}\u{89c6}\u{9891}\u{5df2}\u{8fbe}\u{5230}\u{6295}\u{5e01}\u{4e0a}\u{9650}\u{3002}"
    static let videoLiked = "\u{5df2}\u{70b9}\u{8d5e}\u{8fd9}\u{4e2a}\u{89c6}\u{9891}\u{3002}"
    static let videoUnliked = "\u{5df2}\u{53d6}\u{6d88}\u{70b9}\u{8d5e}\u{3002}"
    static let videoFavoriteRemoved = "\u{5df2}\u{53d6}\u{6d88}\u{6536}\u{85cf}\u{3002}"

    static let nativePlayerTitle = "\u{539f}\u{751f}\u{64ad}\u{653e}\u{5668}"
    static let nativePlayerResolving = "\u{6b63}\u{5728}\u{89e3}\u{6790}\u{64ad}\u{653e}\u{5730}\u{5740}..."
    static let nativePlayerWebFallback = "\u{6539}\u{7528}\u{7f51}\u{9875}\u{64ad}\u{653e}"
    static let nativePlayerCompatibilitySubtitle = "\u{67d0}\u{4e9b}\u{89c6}\u{9891}\u{5728}\u{7f51}\u{9875}\u{5185}\u{64ad}\u{653e}\u{65f6}\u{4f1a}\u{62ff}\u{5230}\u{66f4}\u{5b8c}\u{6574}\u{7684}\u{80fd}\u{529b}"
    static let playerModeTitle = "\u{64ad}\u{653e}\u{6a21}\u{5f0f}"
    static let playerModeSubtitle = "\u{8bb0}\u{4f4f}\u{4f60}\u{66f4}\u{5e38}\u{7528}\u{7684}\u{64ad}\u{653e}\u{5165}\u{53e3}"
    static let playerModeNative = "\u{539f}\u{751f}"
    static let playerModeCompatibility = "\u{517c}\u{5bb9} Web"
    static let playerModeRemembered = "\u{5df2}\u{8bb0}\u{4f4f}"
    static let playerCompatibilityModeHint = "\u{5f53}\u{524d}\u{9ed8}\u{8ba4}\u{4f1a}\u{8d70} Web \u{517c}\u{5bb9}\u{64ad}\u{653e}\u{5165}\u{53e3}"
    static let playerCompatibilityModeBody = "\u{517c}\u{5bb9} Web \u{6a21}\u{5f0f}\u{4f1a}\u{8df3}\u{8f6c}\u{5230}\u{7f51}\u{9875}\u{5185}\u{64ad}\u{653e}\u{5668}\u{ff0c}\u{9002}\u{5408}\u{90a3}\u{4e9b}\u{9700}\u{8981}\u{66f4}\u{5b8c}\u{6574}\u{80fd}\u{529b}\u{7684}\u{89c6}\u{9891}"
    static let playerOpenCompatibility = "\u{6253}\u{5f00} Web \u{517c}\u{5bb9}\u{64ad}\u{653e}"
    static let playerSwitchToNative = "\u{5207}\u{56de}\u{539f}\u{751f}\u{64ad}\u{653e}"
    static let playerTitle = "\u{64ad}\u{653e}\u{5668}"
    static let playerControlsTitle = "\u{64ad}\u{653e}\u{63a7}\u{5236}"
    static let playerGestureHint = "\u{5355}\u{51fb}\u{663e}\u{793a}\u{63a7}\u{5236}\u{ff0c}\u{6ed1}\u{52a8}\u{53ef}\u{5feb}\u{8fdb}\u{3001}\u{8c03}\u{4eae}\u{5ea6}\u{548c}\u{97f3}\u{91cf}"
    static let playerAspectTitle = "\u{753b}\u{9762}\u{6bd4}\u{4f8b}"
    static let playerAspectContain = "\u{5b8c}\u{6574}\u{663e}\u{793a}"
    static let playerAspectFill = "\u{94fa}\u{6ee1}\u{88c1}\u{5207}"
    static let playerAspectStretch = "\u{62c9}\u{4f38}\u{586b}\u{5145}"
    static let playerDoubleTapPlay = "\u{53cc}\u{51fb}\u{7ee7}\u{7eed}\u{64ad}\u{653e}"
    static let playerDoubleTapPause = "\u{53cc}\u{51fb}\u{6682}\u{505c}\u{64ad}\u{653e}"
    static let playerSpeedBoosting = "\u{957f}\u{6309} 2x \u{500d}\u{901f}"
    static let playerFullscreenEnterGesture = "\u{4e0a}\u{6ed1}\u{8fdb}\u{5165}\u{5168}\u{5c4f}"
    static let playerFullscreenExitGesture = "\u{4e0b}\u{6ed1}\u{9000}\u{51fa}\u{5168}\u{5c4f}"
    static let playerFullscreenEnterCancel = "\u{7ee7}\u{7eed}\u{4e0a}\u{6ed1}\u{53ef}\u{8fdb}\u{5165}\u{5168}\u{5c4f}"
    static let playerFullscreenExitCancel = "\u{7ee7}\u{7eed}\u{4e0b}\u{6ed1}\u{53ef}\u{9000}\u{51fa}\u{5168}\u{5c4f}"
    static let nativeDirectNote = "\u{5f53}\u{524d}\u{4f7f}\u{7528}\u{539f}\u{751f}\u{76f4}\u{94fe}\u{64ad}\u{653e}\u{3002}"
    static let nativeVideoOnlyNote = "\u{5f53}\u{524d}\u{89c6}\u{9891}\u{672a}\u{8fd4}\u{56de}\u{72ec}\u{7acb}\u{97f3}\u{8f68}\u{ff0c}\u{5148}\u{5c1d}\u{8bd5}\u{7eaf}\u{89c6}\u{9891}\u{64ad}\u{653e}\u{3002}"
    static let nativeDashNote = "\u{5df2}\u{5207}\u{6362}\u{5230}\u{539f}\u{751f} DASH \u{9996}\u{9009}\u{6d41}\u{ff0c}\u{6b63}\u{5728}\u{5408}\u{6210}\u{97f3}\u{89c6}\u{9891}\u{8f68}\u{9053}\u{3002}"
    static let nativeFallbackNote = "\u{5f53}\u{524d}\u{6ca1}\u{6709}\u{62ff}\u{5230}\u{53ef}\u{5e94}\u{7528}\u{5185}\u{64ad}\u{653e}\u{7684}\u{539f}\u{751f}\u{6d41}\u{5730}\u{5740}\u{ff0c}\u{8bf7}\u{5207}\u{6362}\u{5176}\u{4ed6}\u{753b}\u{8d28}\u{6216}\u{7a0d}\u{540e}\u{91cd}\u{8bd5}\u{3002}"
    static let nativeStreamUnavailable = "\u{5f53}\u{524d}\u{89c6}\u{9891}\u{6d41}\u{6682}\u{65f6}\u{4e0d}\u{53ef}\u{7528}\u{ff0c}\u{8bf7}\u{5207}\u{6362}\u{5176}\u{4ed6}\u{753b}\u{8d28}\u{6216}\u{6539}\u{7528}\u{7f51}\u{9875}\u{64ad}\u{653e}\u{3002}"
    static let nativePlaybackFailed = "\u{539f}\u{751f}\u{64ad}\u{653e}\u{5668}\u{8bfb}\u{53d6}\u{89c6}\u{9891}\u{6d41}\u{5931}\u{8d25}\u{ff0c}\u{8bf7}\u{5c1d}\u{8bd5}\u{5207}\u{6362}\u{5230}\u{76f4}\u{94fe}\u{6216}\u{7f51}\u{9875}\u{64ad}\u{653e}\u{3002}"
    static let nativePlaybackStalled = "\u{5f53}\u{524d}\u{89c6}\u{9891}\u{6d41}\u{52a0}\u{8f7d}\u{8f83}\u{6162}\u{6216}\u{5df2}\u{88ab}\u{9650}\u{5236}\u{ff0c}\u{53ef}\u{4ee5}\u{7a0d}\u{540e}\u{91cd}\u{8bd5}\u{6216}\u{5207}\u{6362}\u{5230}\u{5176}\u{4ed6}\u{6e05}\u{6670}\u{5ea6}\u{3002}"
    static let qualityTitle = "\u{6e05}\u{6670}\u{5ea6}"
    static let currentQuality = "\u{5f53}\u{524d}\u{753b}\u{8d28}"
    static let danmakuTitle = "\u{5f39}\u{5e55}"
    static let danmakuLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{5f39}\u{5e55}..."
    static let danmakuEmpty = "\u{6682}\u{65e0}\u{53ef}\u{663e}\u{793a}\u{5f39}\u{5e55}"
    static let danmakuOverlayOn = "\u{5f39}\u{5e55}\u{8986}\u{76d6}\u{5df2}\u{5f00}\u{542f}"
    static let danmakuOverlayOff = "\u{5f39}\u{5e55}\u{8986}\u{76d6}\u{5df2}\u{5173}\u{95ed}"
    static let liveDanmaku = "\u{8ddf}\u{968f}\u{64ad}\u{653e}\u{663e}\u{793a}"
    static let danmakuTrackStyle = "\u{8f68}\u{9053}\u{5f39}\u{5e55}"
    static let danmakuSampleSubtitle = "\u{524d} 12 \u{6761}\u{5f39}\u{5e55}\u{6837}\u{672c}"
    static let loginSyncTitle = "\u{767b}\u{5f55}\u{540c}\u{6b65}"
    static let loginSyncSubtitle = "\u{5e94}\u{7528}\u{56de}\u{5230}\u{524d}\u{53f0}\u{65f6}\u{4f1a}\u{81ea}\u{52a8}\u{5408}\u{5e76} WebKit \u{4e0e}\u{539f}\u{751f} Cookie \u{767b}\u{5f55}\u{6001}\u{3002}"
    static let syncNow = "\u{7acb}\u{5373}\u{540c}\u{6b65}"
    static let justUpdated = "\u{521a}\u{521a}\u{66f4}\u{65b0}"
    static let profileSyncStatus = "\u{767b}\u{5f55}\u{72b6}\u{6001}\u{5df2}\u{4e0e} Cookie \u{540c}\u{6b65}"
    static let homeHeroBadge = "\u{539f}\u{751f}\u{91cd}\u{5199}\u{4e2d}"
    static let homeHeroSubtitle = "\u{5c06}\u{63a8}\u{8350}\u{6d41}\u{3001}\u{767b}\u{5f55}\u{8fc1}\u{79fb}\u{548c}\u{64ad}\u{653e}\u{80fd}\u{529b}\u{5408}\u{5230}\u{4e00}\u{4e2a} SwiftUI \u{7248}\u{672c}"
    static let homeNativeSubtitle = "\u{7528} SwiftUI \u{539f}\u{751f}\u{91cd}\u{7ec4}\u{63a8}\u{8350}\u{3001}\u{641c}\u{7d22}\u{4e0e}\u{4e2a}\u{4eba}\u{7a7a}\u{95f4}\u{3002}"
    static let homeFeaturedTitle = "\u{4eca}\u{65e5}\u{7cbe}\u{9009}"
    static let homeFeaturedSubtitle = "\u{628a}\u{5f53}\u{524d}\u{9891}\u{9053}\u{91cc}\u{6700}\u{503c}\u{5f97}\u{7acb}\u{5373}\u{70b9}\u{5f00}\u{7684}\u{5185}\u{5bb9}\u{653e}\u{5230}\u{6700}\u{524d}\u{9762}"
    static let homeRecommendedSubtitleCount = "\u{6761}\u{63a8}\u{8350}"
    static let homeQuickActionsSubtitle = "\u{641c}\u{7d22}\u{3001}\u{70ed}\u{95e8}\u{3001}\u{8fdc}\u{7a0b}\u{5386}\u{53f2}\u{548c}\u{4e2a}\u{4eba}\u{5165}\u{53e3}\u{90fd}\u{653e}\u{5728}\u{9996}\u{9875}"
    static let homeLiveTitle = "\u{70ed}\u{95e8}\u{76f4}\u{64ad}"
    static let homeLiveSubtitle = "\u{5148}\u{770b}\u{5f53}\u{4e0b}\u{6bd4}\u{8f83}\u{6d3b}\u{8dc3}\u{7684}\u{76f4}\u{64ad}\u{95f4}\u{548c}\u{4e3b}\u{64ad}"
    static let homeBangumiTitle = "\u{756a}\u{5267}\u{699c}\u{5355}"
    static let homeBangumiSubtitle = "\u{628a}\u{8fd1}\u{671f}\u{503c}\u{5f97}\u{5148}\u{770b}\u{7684}\u{756a}\u{5267}\u{5185}\u{5bb9}\u{653e}\u{5230}\u{9996}\u{9875}"
    static let homeSearchActionSubtitle = "\u{76f4}\u{63a5}\u{6253}\u{5f00}\u{8054}\u{60f3}\u{3001}\u{70ed}\u{8bcd}\u{548c}\u{641c}\u{7d22}\u{5386}\u{53f2}"
    static let homeHotActionSubtitle = "\u{7acb}\u{523b}\u{5207}\u{5230}\u{70ed}\u{95e8}\u{6d41}\u{3001}\u{770b}\u{770b}\u{4eca}\u{5929}\u{5927}\u{5bb6}\u{90fd}\u{5728}\u{70b9}\u{4ec0}\u{4e48}"
    static let homeDynamicActionSubtitle = "\u{6253}\u{5f00}\u{767b}\u{5f55}\u{540e}\u{7684}\u{52a8}\u{6001}\u{6d41}\u{ff0c}\u{770b}\u{5173}\u{6ce8} UP \u{4e3b}\u{6700}\u{65b0}\u{5185}\u{5bb9}"
    static let homeLibraryActionSubtitle = "\u{628a}\u{6536}\u{85cf}\u{5939}\u{3001}\u{5386}\u{53f2}\u{548c}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{96c6}\u{4e2d}\u{8fdb}\u{5165}"
    static let homeHistoryActionSubtitle = "\u{76f4}\u{63a5}\u{67e5}\u{770b}\u{8d26}\u{53f7}\u{7684}\u{8fdc}\u{7a0b}\u{89c2}\u{770b}\u{5386}\u{53f2}"
    static let homeProfileActionSubtitle = "\u{7ee7}\u{7eed}\u{540c}\u{6b65} Cookie\u{3001}\u{8d26}\u{53f7}\u{72b6}\u{6001}\u{4e0e}\u{8fdc}\u{7a0b}\u{5386}\u{53f2}\u{5165}\u{53e3}"
    static let homeHighlightsTitle = "\u{5feb}\u{901f}\u{9884}\u{89c8}"
    static let searchDiscoveryTitle = "\u{53d1}\u{73b0}\u{63a2}\u{7d22}"
    static let searchDiscoverySubtitle2 = "\u{628a}\u{70ed}\u{95e8}\u{8bcd}\u{548c}\u{63a8}\u{8350}\u{8bcd}\u{505a}\u{6210}\u{66f4}\u{76f4}\u{89c2}\u{7684}\u{9996}\u{5c4f}\u{5165}\u{53e3}"
    static let searchHeroSubtitle = "\u{70ed}\u{8bcd}\u{3001}\u{8054}\u{60f3}\u{8bcd}\u{3001}\u{5386}\u{53f2}\u{8bb0}\u{5f55}\u{90fd}\u{5df2}\u{7ecf}\u{63a5}\u{5165}\u{539f}\u{751f}\u{641c}\u{7d22}\u{6d41}\u{7a0b}"
    static let searchDiscoverySubtitle = "\u{628a}\u{70ed}\u{8bcd}\u{3001}\u{8054}\u{60f3}\u{8bcd}\u{548c}\u{641c}\u{7d22}\u{5386}\u{53f2}\u{91cd}\u{7ec4}\u{6210}\u{66f4}\u{50cf} iOS \u{539f}\u{751f}\u{641c}\u{7d22}\u{9762}\u{677f}\u{7684}\u{4f53}\u{9a8c}"
    static let searchSpotlightTitle = "\u{70ed}\u{95e8}\u{805a}\u{7126}"
    static let searchBestMatchTitle = "\u{6700}\u{4f73}\u{5339}\u{914d}"
    static let searchBestMatchSubtitle = "\u{628a}\u{6700}\u{503c}\u{5f97}\u{5148}\u{70b9}\u{7684}\u{89c6}\u{9891}\u{653e}\u{5728}\u{6700}\u{4e0a}\u{9762}"
    static let searchContinueWatchingTitle = "\u{641c}\u{7d22}\u{7eed}\u{64ad}"
    static let relatedSubtitle = "\u{7ee7}\u{7eed}\u{987a}\u{7740}\u{76f8}\u{5173}\u{89c6}\u{9891}\u{5f80}\u{4e0b}\u{770b}"
    static let pageSubtitle = "\u{9009}\u{62e9}\u{4e0d}\u{540c} P \u{6570}\u{8fdb}\u{884c}\u{64ad}\u{653e}"
    static let playbackPanelTitle = "\u{64ad}\u{653e}\u{65b9}\u{5f0f}"
    static let detailActionsSubtitle = "\u{5728}\u{539f}\u{751f}\u{64ad}\u{653e}\u{548c}\u{7f51}\u{9875}\u{64ad}\u{653e}\u{4e4b}\u{95f4}\u{5207}\u{6362}"
    static let actionPanelTitle = "\u{4e92}\u{52a8}\u{4e0e}\u{64ad}\u{653e}"
    static let actionPanelSubtitle = "\u{628a}\u{70b9}\u{8d5e}\u{3001}\u{6295}\u{5e01}\u{3001}\u{6536}\u{85cf}\u{548c}\u{65ad}\u{70b9}\u{64ad}\u{653e}\u{653e}\u{5728}\u{4e00}\u{8d77}"
    static let resumeProgressSubtitle = "\u{68c0}\u{6d4b}\u{5230}\u{672c}\u{5730}\u{65ad}\u{70b9}\u{8fdb}\u{5ea6}"
    static let videoDetailOverviewTitle = "\u{89c2}\u{770b}\u{6982}\u{89c8}"
    static let videoDetailOverviewSubtitle = "\u{628a}\u{65f6}\u{957f}\u{3001}\u{53d1}\u{5e03}\u{65f6}\u{95f4}\u{3001}\u{7eed}\u{64ad}\u{548c} P \u{6570}\u{4fe1}\u{606f}\u{6536}\u{5230}\u{4e00}\u{5c42}"
    static let videoDetailDescriptionTitle = "\u{7b80}\u{4ecb}"
    static let videoDetailDurationTitle = "\u{65f6}\u{957f}"
    static let videoDetailPublishedTitle = "\u{53d1}\u{5e03}\u{65f6}\u{95f4}"
    static let videoDetailWatchingTitle = "\u{5f53}\u{524d}\u{8fdb}\u{5ea6}"
    static let videoDetailWatchingEmpty = "\u{8fd8}\u{6ca1}\u{6709}\u{65ad}\u{70b9}"
    static let videoDetailSinglePart = "\u{5355} P \u{89c6}\u{9891}"
    static let videoDetailExpandDescription = "\u{5c55}\u{5f00}\u{7b80}\u{4ecb}"
    static let videoDetailCollapseDescription = "\u{6536}\u{8d77}\u{7b80}\u{4ecb}"
    static let detailAuthorSubtitle = "UP \u{4e3b}\u{4e0e}\u{6295}\u{7a3f}\u{4fe1}\u{606f}"
    static let favoritesSubtitle = "\u{540c}\u{6b65}\u{4f60}\u{7684}\u{516c}\u{5f00}\u{6536}\u{85cf}\u{5939}\u{548c}\u{5185}\u{5bb9}\u{6570}"
    static let commonActionsSubtitle = "\u{8fdc}\u{7a0b}\u{5386}\u{53f2}\u{3001} Cookie \u{540c}\u{6b65}\u{548c}\u{767b}\u{5f55}\u{5165}\u{53e3}\u{5df2}\u{7ecf}\u{6574}\u{5408}"
    static let profileHeroSubtitle = "\u{8d26}\u{53f7}\u{4fe1}\u{606f}\u{3001} Cookie \u{540c}\u{6b65}\u{548c}\u{8fdc}\u{7a0b}\u{5386}\u{53f2}\u{90fd}\u{5728}\u{8fd9}\u{4e2a}\u{539f}\u{751f}\u{4e2a}\u{4eba}\u{9875}"
    static let profileFocusTitle = "\u{8d26}\u{53f7}\u{91cd}\u{70b9}"
    static let profileFocusSubtitle = "\u{53ea}\u{628a}\u{767b}\u{5f55}\u{3001}\u{8fdc}\u{7a0b}\u{5386}\u{53f2}\u{548c} Cookie \u{72b6}\u{6001}\u{6536}\u{5230}\u{4e00}\u{8d77}"
    static let profileFocusSessionTitle = "\u{767b}\u{5f55}\u{72b6}\u{6001}"
    static let profileCookieFieldsTitle = "Cookie \u{5b57}\u{6bb5}"
    static let browsingModeTitle = "\u{6d4f}\u{89c8}\u{6a21}\u{5f0f}"
    static let browsingModeSubtitle = "\u{63a7}\u{5236}\u{63a8}\u{8350}\u{548c}\u{64ad}\u{653e}\u{662f}\u{5426}\u{4f7f}\u{7528}\u{767b}\u{5f55}\u{6001}"
    static let guestModeTitle = "\u{6e38}\u{5ba2}\u{63a8}\u{8350}"
    static let guestModeSubtitle = "\u{9996}\u{9875}\u{63a8}\u{8350}\u{6d41}\u{4ee5}\u{672a}\u{767b}\u{5f55}\u{72b6}\u{6001}\u{62c9}\u{53d6}"
    static let incognitoPlaybackTitle = "\u{65e0}\u{75d5}\u{64ad}\u{653e}"
    static let incognitoPlaybackSubtitle = "\u{64ad}\u{653e}\u{65f6}\u{4e0d}\u{4e0a}\u{62a5}\u{5386}\u{53f2}\u{4e5f}\u{4e0d}\u{8bfb}\u{53d6}\u{4e91}\u{7aef}\u{65ad}\u{70b9}"
    static let profileHistorySubtitle = "\u{67e5}\u{770b}\u{8fd1}\u{671f}\u{89c2}\u{770b}\u{8f68}\u{8ff9}\u{4e0e}\u{539f}\u{751f}\u{8fdb}\u{5ea6}"
    static let profileWatchLaterSubtitle = "\u{7a0d}\u{540e}\u{518d}\u{770b}\u{5df2}\u{4ece}\u{5f53}\u{524d}\u{7248}\u{672c}\u{7684}\u{91cd}\u{70b9}\u{8303}\u{56f4}\u{4e2d}\u{79fb}\u{51fa}"
    static let profileContinueWatchingSubtitle = "\u{672c}\u{5730}\u{7eed}\u{64ad}\u{5df2}\u{4ece}\u{5f53}\u{524d}\u{7248}\u{672c}\u{7684}\u{91cd}\u{70b9}\u{8303}\u{56f4}\u{4e2d}\u{79fb}\u{51fa}"
    static let profileContinueWatchingSectionSubtitle = "\u{672c}\u{5730}\u{65ad}\u{70b9}\u{5df2}\u{4ece}\u{5f53}\u{524d}\u{7248}\u{672c}\u{7684}\u{91cd}\u{70b9}\u{8303}\u{56f4}\u{4e2d}\u{79fb}\u{51fa}"
    static let profileWebLoginSubtitle = "\u{5728}\u{5185}\u{5d4c} Web \u{91cc}\u{5b8c}\u{6210}\u{767b}\u{5f55}\u{540e}\u{76f4}\u{63a5}\u{5bfc}\u{5165} Cookie"
    static let profileCookieSubtitle = "\u{624b}\u{52a8}\u{7c98}\u{8d34}\u{6d4f}\u{89c8}\u{5668} Cookie Header \u{540c}\u{6b65}\u{767b}\u{5f55}\u{72b6}\u{6001}"
    static let loginGuideSubtitle = "\u{5bfc}\u{5165} Cookie \u{540e}\u{5373}\u{53ef}\u{8fc1}\u{79fb}\u{5386}\u{53f2}\u{3001}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{548c}\u{6536}\u{85cf}"
    static let nativeReady = "\u{53ef}\u{5207}\u{6362}\u{753b}\u{8d28}\u{4e0e}\u{67e5}\u{770b}\u{57fa}\u{7840}\u{5f39}\u{5e55}"
    static let libraryHeroSubtitle = "\u{628a}\u{5386}\u{53f2}\u{3001}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{4e0e}\u{6536}\u{85cf}\u{5939}\u{5347}\u{7ea7}\u{6210}\u{4e00}\u{4e2a}\u{72ec}\u{7acb}\u{7684}\u{539f}\u{751f}\u{7247}\u{5e93}\u{5165}\u{53e3}"
    static let libraryActionsSubtitle = "\u{5df2}\u{8fc1}\u{79fb}\u{7684}\u{4e09}\u{7c7b}\u{5185}\u{5bb9}\u{5728}\u{8fd9}\u{91cc}\u{96c6}\u{4e2d}\u{8fdb}\u{5165}"
    static let libraryHistorySubtitle = "\u{7eed}\u{63a5}\u{4f60}\u{7684}\u{89c2}\u{770b}\u{5386}\u{53f2}\u{548c}\u{5df2}\u{770b}\u{8fdb}\u{5ea6}"
    static let libraryWatchLaterSubtitle = "\u{5c06}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{5217}\u{8868}\u{4f5c}\u{4e3a}\u{72ec}\u{7acb}\u{6a21}\u{5757}\u{5feb}\u{901f}\u{6253}\u{5f00}"
    static let libraryContinueWatchingActionSubtitle = "\u{7edf}\u{4e00}\u{7ba1}\u{7406}\u{672c}\u{5730}\u{65ad}\u{70b9}\u{548c}\u{7eed}\u{64ad}\u{8fdb}\u{5ea6}"
    static let librarySearchSubtitle = "\u{7ee7}\u{7eed}\u{53bb}\u{641c}\u{89c6}\u{9891}\u{3001}UP \u{4e3b}\u{548c}\u{5173}\u{952e}\u{8bcd}"
    static let libraryProfileSubtitle = "\u{524d}\u{5f80}\u{6211}\u{7684}\u{9875}\u{7ba1}\u{7406} Cookie \u{548c}\u{767b}\u{5f55}\u{540c}\u{6b65}"
    static let libraryFavoritesEmptySubtitle = "\u{767b}\u{5f55}\u{5e76}\u{540c}\u{6b65}\u{6210}\u{529f}\u{540e}\u{ff0c}\u{8fd9}\u{91cc}\u{4f1a}\u{51fa}\u{73b0}\u{4f60}\u{7684}\u{6536}\u{85cf}\u{5939}\u{9884}\u{89c8}"
    static let libraryMigrationSubtitle = "\u{539f}\u{751f}\u{7248}\u{672c}\u{76ee}\u{524d}\u{5df2}\u{652f}\u{6301}\u{767b}\u{5f55}\u{3001}\u{5386}\u{53f2}\u{3001}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{548c}\u{6536}\u{85cf}\u{8fc1}\u{79fb}"
    static let libraryLoginTitle = "\u{767b}\u{5f55}\u{540e}\u{540c}\u{6b65}\u{7247}\u{5e93}"
    static let libraryLoginSubtitle = "\u{5f53}\u{524d}\u{7247}\u{5e93}\u{9700}\u{8981} Cookie \u{6216} Web \u{767b}\u{5f55}\u{540e}\u{624d}\u{80fd}\u{62ff}\u{5230}\u{4f60}\u{7684}\u{5386}\u{53f2}\u{3001}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{548c}\u{6536}\u{85cf}\u{5939}"
    static let libraryLoginAction = "\u{53bb}\u{767b}\u{5f55}"
    static let libraryOverviewTitle = "\u{7247}\u{5e93}\u{6982}\u{89c8}"
    static let libraryOverviewSubtitle = "\u{5728}\u{540c}\u{4e00}\u{5c42}\u{770b}\u{5230}\u{767b}\u{5f55}\u{72b6}\u{6001}\u{3001}\u{6536}\u{85cf}\u{5939}\u{548c}\u{539f}\u{751f}\u{8fc1}\u{79fb}\u{8fdb}\u{5ea6}"
    static let librarySessionCardTitle = "\u{5f53}\u{524d}\u{8d26}\u{53f7}"
    static let librarySpotlightTitle = "\u{4f18}\u{5148}\u{9605}\u{8bfb}"
    static let libraryLoggedInBadge = "\u{5df2}\u{767b}\u{5f55}"
    static let libraryNativeBadge = "\u{539f}\u{751f}"
    static let libraryReadyBadge = "\u{5c31}\u{7eea}"
    static let dynamicHeroSubtitle = "\u{767b}\u{5f55}\u{540e}\u{53ef}\u{4ee5}\u{76f4}\u{63a5}\u{67e5}\u{770b}\u{5173}\u{6ce8}\u{3001}\u{89c6}\u{9891}\u{5206}\u{6d41}\u{548c}\u{8f6c}\u{53d1}\u{52a8}\u{6001}\u{3002}"
    static let dynamicFeedAll = "\u{63a8}\u{8350}\u{52a8}\u{6001}"
    static let dynamicFeedVideo = "\u{89c6}\u{9891}\u{52a8}\u{6001}"
    static let dynamicSessionHint = "\u{9700}\u{8981}\u{767b}\u{5f55}"
    static let dynamicLoginTitle = "\u{767b}\u{5f55}\u{540e}\u{89e3}\u{9501}\u{52a8}\u{6001}"
    static let dynamicLoginSubtitle = "\u{5f53}\u{524d}\u{52a8}\u{6001}\u{6d41}\u{4f9d}\u{8d56}\u{767b}\u{5f55} Cookie \u{624d}\u{80fd}\u{62ff}\u{5230}\u{4f60}\u{7684}\u{5173}\u{6ce8}\u{5185}\u{5bb9}"
    static let dynamicLoginBody = "\u{8fdb}\u{5165}\u{201c}\u{6211}\u{7684}\u{201d}\u{5b8c}\u{6210} Web \u{767b}\u{5f55}\u{6216} Cookie \u{5bfc}\u{5165}\u{540e}\u{ff0c}\u{8fd9}\u{91cc}\u{4f1a}\u{81ea}\u{52a8}\u{663e}\u{793a}\u{52a8}\u{6001}\u{6d41}\u{3002}"
    static let dynamicLoginAction = "\u{53bb}\u{6211}\u{7684}"
    static let dynamicLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{52a8}\u{6001}\u{6d41}..."
    static let dynamicEmptyTitle = "\u{8fd8}\u{6ca1}\u{6709}\u{52a8}\u{6001}"
    static let dynamicEmptySubtitle = "\u{53ef}\u{4ee5}\u{4e0b}\u{62c9}\u{5237}\u{65b0}\u{ff0c}\u{6216}\u{7a0d}\u{540e}\u{518d}\u{8bd5}\u{4e00}\u{6b21}\u{3002}"
    static let dynamicReloadAction = "\u{91cd}\u{65b0}\u{52a0}\u{8f7d}\u{52a8}\u{6001}"
    static let dynamicDetailTitle = "\u{52a8}\u{6001}\u{8be6}\u{60c5}"
    static let dynamicDetailSubtitle = "\u{67e5}\u{770b}\u{5b8c}\u{6574}\u{5185}\u{5bb9}\u{3001}\u{8f6c}\u{53d1}\u{4e0e}\u{5bf9}\u{5e94}\u{8bc4}\u{8bba}\u{3002}"
    static let dynamicDetailLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{52a8}\u{6001}\u{8be6}\u{60c5}..."
    static let dynamicReadingTitle = "\u{6b63}\u{6587}"
    static let dynamicReadingEmpty = "\u{8fd9}\u{6761}\u{52a8}\u{6001}\u{66f4}\u{50cf}\u{4e00}\u{4e2a}\u{9644}\u{4ef6}\u{5361}\u{7247}\u{ff0c}\u{6ca1}\u{6709}\u{53ef}\u{5c55}\u{5f00}\u{7684}\u{957f}\u{6587}\u{3002}"
    static let dynamicExpandText = "\u{5c55}\u{5f00}\u{5168}\u{6587}"
    static let dynamicCollapseText = "\u{6536}\u{8d77}\u{5168}\u{6587}"
    static let dynamicMediaTitle = "\u{56fe}\u{96c6}"
    static let dynamicAttachedVideoTitle = "\u{9644}\u{5e26}\u{89c6}\u{9891}"
    static let dynamicAttachedVideoSubtitle = "\u{4fdd}\u{7559}\u{5728}\u{52a8}\u{6001}\u{91cc}\u{7684}\u{53ef}\u{70b9}\u{5f00}\u{5185}\u{5bb9}"
    static let dynamicQuotedTitle = "\u{539f}\u{52a8}\u{6001}"
    static let userProfileLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{7528}\u{6237}\u{4e3b}\u{9875}..."
    static let userProfileMissingMID = "\u{5f53}\u{524d}\u{7528}\u{6237}\u{7f3a}\u{5c11} mid\u{ff0c}\u{6682}\u{65f6}\u{65e0}\u{6cd5}\u{52a0}\u{8f7d}\u{4e3b}\u{9875}\u{3002}"
    static let userProfileFollowLoginHint = "\u{8bf7}\u{5148}\u{767b}\u{5f55}\u{540e}\u{518d}\u{64cd}\u{4f5c}\u{5173}\u{6ce8}\u{3002}"
    static let userProfileFollowAction = "\u{5173}\u{6ce8}"
    static let userProfileUnfollowAction = "\u{53d6}\u{6d88}\u{5173}\u{6ce8}"
    static let userProfileFollowed = "\u{5df2}\u{5173}\u{6ce8}\u{8be5}\u{7528}\u{6237}\u{3002}"
    static let userProfileUnfollowed = "\u{5df2}\u{53d6}\u{6d88}\u{5173}\u{6ce8}\u{3002}"
    static let userProfileRelationTitle = "\u{5173}\u{7cfb}\u{6982}\u{89c8}"
    static let userProfileRelationSubtitle = "\u{67e5}\u{770b}\u{5173}\u{6ce8}\u{3001}\u{7c89}\u{4e1d}\u{548c}\u{8fd1}\u{671f}\u{5185}\u{5bb9}"
    static let userRelationFollowings = "\u{5173}\u{6ce8}"
    static let userRelationFans = "\u{7c89}\u{4e1d}"
    static let userProfileArchiveCount = "\u{6295}\u{7a3f}"
    static let userProfileRecentVideos = "\u{8fd1}\u{671f}\u{89c6}\u{9891}"
    static let userProfileNoRecentVideosTitle = "\u{6682}\u{65e0}\u{6700}\u{65b0}\u{89c6}\u{9891}"
    static let userProfileNoRecentVideosSubtitle = "\u{8fd9}\u{4e2a}\u{7528}\u{6237}\u{8fd1}\u{671f}\u{8fd8}\u{6ca1}\u{6709}\u{53ef}\u{5c55}\u{793a}\u{7684}\u{89c6}\u{9891}\u{3002}"
    static let userRelationLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{7528}\u{6237}\u{5217}\u{8868}..."
    static let userRelationEmptySubtitle = "\u{5f53}\u{524d}\u{8fd8}\u{6ca1}\u{6709}\u{53ef}\u{663e}\u{793a}\u{7684}\u{7528}\u{6237}\u{3002}"
    static let userProfileOfficialBadge = "\u{8ba4}\u{8bc1}"
    static let userProfileFollowingBadge = "\u{5df2}\u{5173}\u{6ce8}"
    static let playerOverviewTitle = "\u{64ad}\u{653e}\u{6982}\u{89c8}"
    static let playerOverviewSubtitle = "\u{7528}\u{66f4}\u{8f7b}\u{677e}\u{7684}\u{65b9}\u{5f0f}\u{770b}\u{6e05}\u{5f53}\u{524d}\u{5185}\u{5bb9}\u{548c}\u{5feb}\u{901f}\u{5b9a}\u{4f4d}"
    static let playerFastStartBadge = "\u{5feb}\u{901f}\u{8d77}\u{64ad}"
    static let playerRestart = "\u{56de}\u{5230}\u{5f00}\u{5934}"
    static let playerQuarter = "25%"
    static let playerHalf = "50%"
    static let playerThreeQuarter = "75%"
    static let playerAlmostDone = "\u{5feb}\u{5230}\u{7ed3}\u{5c3e}"
    static let videoCommentsTitle = "\u{8bc4}\u{8bba}"
    static let videoCommentsSubtitle = "\u{89c2}\u{770b}\u{70ed}\u{95e8}\u{8bc4}\u{8bba}\u{548c}\u{6700}\u{65b0}\u{56de}\u{590d}"
    static let videoCommentsSortHot = "\u{70ed}\u{95e8}"
    static let videoCommentsSortNew = "\u{6700}\u{65b0}"
    static let videoCommentsPreparing = "\u{6b63}\u{5728}\u{51c6}\u{5907}\u{8bc4}\u{8bba}\u{53c2}\u{6570}..."
    static let videoCommentsLoading = "\u{6b63}\u{5728}\u{52a0}\u{8f7d}\u{8bc4}\u{8bba}..."
    static let videoCommentsEmptyTitle = "\u{8fd8}\u{6ca1}\u{6709}\u{8bc4}\u{8bba}"
    static let videoCommentsEmptySubtitle = "\u{5f53}\u{524d}\u{89c6}\u{9891}\u{8fd8}\u{6ca1}\u{6709}\u{53ef}\u{89c1}\u{8bc4}\u{8bba}\u{6216}\u{8bc4}\u{8bba}\u{672a}\u{80fd}\u{6210}\u{529f}\u{52a0}\u{8f7d}\u{3002}"
    static let videoCommentsReloadAction = "\u{91cd}\u{65b0}\u{52a0}\u{8f7d}\u{8bc4}\u{8bba}"
    static let videoCommentsPinnedTitle = "\u{7f6e}\u{9876}\u{4e0e}\u{70ed}\u{95e8}"
    static let videoCommentsPinnedTag = "\u{7cbe}\u{9009}"
    static let videoCommentsExpandText = "\u{5c55}\u{5f00}\u{5168}\u{6587}"
    static let videoCommentsCollapseText = "\u{6536}\u{8d77}\u{5168}\u{6587}"
    static let videoCommentsReplyAction = "\u{56de}\u{590d}"
    static let videoCommentsDetailAction = "\u{67e5}\u{770b}\u{8be6}\u{60c5}"
    static let videoCommentsLikeUnavailable = "\u{5f53}\u{524d}\u{8bc4}\u{8bba}\u{7f3a}\u{5c11}\u{70b9}\u{8d5e}\u{53c2}\u{6570}\u{ff0c}\u{6682}\u{65f6}\u{4e0d}\u{80fd}\u{64cd}\u{4f5c}\u{3002}"
    static let videoCommentsSendAction = "\u{53d1}\u{9001}"
    static let videoCommentsComposerTitle = "\u{53d1}\u{8868}\u{8bc4}\u{8bba}"
    static let videoCommentsReplyPlaceholder = "\u{8bf4}\u{70b9}\u{4ec0}\u{4e48}\u{5427}..."
    static let videoCommentsPosted = "\u{8bc4}\u{8bba}\u{5df2}\u{53d1}\u{9001}\u{3002}"
    static let videoCommentsReplyPosted = "\u{56de}\u{590d}\u{5df2}\u{53d1}\u{9001}\u{3002}"
    static let videoCommentsLiked = "\u{5df2}\u{70b9}\u{8d5e}\u{8fd9}\u{6761}\u{8bc4}\u{8bba}\u{3002}"
    static let videoCommentsUnliked = "\u{5df2}\u{53d6}\u{6d88}\u{8bc4}\u{8bba}\u{70b9}\u{8d5e}\u{3002}"
    static let videoCommentsThreadTitle = "\u{56de}\u{590d}\u{8be6}\u{60c5}"
    static let videoCommentsThreadEmptyTitle = "\u{8fd8}\u{6ca1}\u{6709}\u{56de}\u{590d}"
    static let videoCommentsThreadEmptySubtitle = "\u{8fd9}\u{6761}\u{8bc4}\u{8bba}\u{6682}\u{65f6}\u{8fd8}\u{6ca1}\u{6709}\u{516c}\u{5f00}\u{56de}\u{590d}\u{3002}"
    static let profileFavoritesSpotlightTitle = "\u{6536}\u{85cf}\u{7126}\u{70b9}"
    static let sourceCount = "\u{4e2a}\u{7247}\u{6e90}"
    static let resultsCount = "\u{6761}\u{7ed3}\u{679c}"
    static let historyCount = "\u{6761}\u{641c}\u{7d22}\u{8bb0}\u{5f55}"
    static let hotKeywordsCount = "\u{4e2a}\u{70ed}\u{95e8}\u{5173}\u{952e}\u{8bcd}"
    static let qualityStreamDash = "DASH \u{5408}\u{6d41}"
    static let qualityStreamDirect = "\u{76f4}\u{94fe}\u{64ad}\u{653e}"
    static let qualityMetaResolution = "\u{5206}\u{8fa8}\u{7387}"
    static let qualityMetaBitrate = "\u{7801}\u{7387}"
    static let qualityMetaCodec = "\u{7f16}\u{7801}"
    static let qualityMetaFrameRate = "\u{5e27}\u{7387}"
    static let qualityMetaDynamicRange = "\u{753b}\u{9762}"
    static let qualityAudioMuxed = "\u{5df2}\u{5408}\u{6210}"
    static let qualityHDR = "HDR"
    static let qualityDolbyVision = "\u{675c}\u{6bd4}\u{89c6}\u{754c}"
    static let playPlayback = "\u{64ad}\u{653e}"
    static let pausePlayback = "\u{6682}\u{505c}"
    static let jumpBackward10 = "\u{540e}\u{9000} 10 \u{79d2}"
    static let jumpForward15 = "\u{524d}\u{8fdb} 15 \u{79d2}"
    static let playbackSpeed = "\u{500d}\u{901f}"
    static let playingStatus = "\u{64ad}\u{653e}\u{4e2d}"
    static let pausedStatus = "\u{5df2}\u{6682}\u{505c}"
    static let continueWatchingTitle = "\u{7ee7}\u{7eed}\u{89c2}\u{770b}"
    static let continueWatchingManageSubtitle = "\u{672c}\u{5730}\u{65ad}\u{70b9}\u{4f1a}\u{968f}\u{64ad}\u{653e}\u{5b9e}\u{65f6}\u{66f4}\u{65b0}\u{ff0c}\u{4e5f}\u{53ef}\u{4ee5}\u{968f}\u{65f6}\u{4ece}\u{5934}\u{5f00}\u{59cb}"
    static let continueWatchingEmptyTitle = "\u{8fd8}\u{6ca1}\u{6709}\u{53ef}\u{7eed}\u{64ad}\u{7684}\u{5185}\u{5bb9}"
    static let continueWatchingEmptySubtitle = "\u{5f53}\u{4f60}\u{770b}\u{5230}\u{4e00}\u{534a}\u{79bb}\u{5f00}\u{89c6}\u{9891}\u{65f6}\u{ff0c}\u{8fd9}\u{91cc}\u{4f1a}\u{81ea}\u{52a8}\u{8bb0}\u{4f4f}\u{65ad}\u{70b9}"
    static let continueWatchingClearAction = "\u{6e05}\u{9664}\u{8fdb}\u{5ea6}"
    static let continueWatchingClearConfirmTitle = "\u{6e05}\u{9664}\u{8fd9}\u{6761}\u{7eed}\u{64ad}\u{8bb0}\u{5f55}\u{ff1f}"
    static let continueWatchingClearConfirmMessage = "\u{6e05}\u{9664}\u{540e}\u{4e0b}\u{6b21}\u{4f1a}\u{4ece}\u{5934}\u{5f00}\u{59cb}\u{64ad}\u{653e}"
    static let continueWatchingClearAllConfirmTitle = "\u{6e05}\u{7a7a}\u{5168}\u{90e8}\u{7eed}\u{64ad}\u{8bb0}\u{5f55}\u{ff1f}"
    static let continueWatchingClearAllConfirmMessage = "\u{8fd9}\u{53ea}\u{4f1a}\u{6e05}\u{7a7a}\u{672c}\u{5730}\u{7eed}\u{64ad}\u{8fdb}\u{5ea6}\u{ff0c}\u{4e0d}\u{4f1a}\u{5220}\u{6389}\u{8d26}\u{53f7}\u{89c2}\u{770b}\u{5386}\u{53f2}"
    static let homeContinueWatchingSubtitle = "\u{6700}\u{8fd1}\u{7684}\u{64ad}\u{653e}\u{65ad}\u{70b9}\u{4f1a}\u{4f18}\u{5148}\u{51fa}\u{73b0}\u{5728}\u{9996}\u{9875}"
    static let libraryContinueWatchingSubtitle = "\u{628a}\u{5386}\u{53f2}\u{3001}\u{6536}\u{85cf}\u{548c}\u{7a0d}\u{540e}\u{518d}\u{770b}\u{7684}\u{8fdb}\u{5ea6}\u{96c6}\u{4e2d}\u{6536}\u{8d77}\u{6765}"
    static let continuePlayback = "\u{7ee7}\u{7eed}\u{64ad}\u{653e}"
    static let playFromBeginning = "\u{4ece}\u{5934}\u{5f00}\u{59cb}"
    static let gestureSeekTo = "\u{62d6}\u{52a8}\u{5230}"
    static let gestureBrightness = "\u{4eae}\u{5ea6}"
    static let gestureVolume = "\u{97f3}\u{91cf}"

    static let unknownTime = "\u{672a}\u{77e5}\u{65f6}\u{95f4}"
    static let unknownUP = "\u{672a}\u{77e5} UP"
    static let unnamedFavoriteFolder = "\u{672a}\u{547d}\u{540d}\u{6536}\u{85cf}\u{5939}"

    static let errorInvalidURL = "\u{65e0}\u{6cd5}\u{6784}\u{9020}\u{8bf7}\u{6c42} URL\u{3002}"
    static let errorInvalidResponse = "\u{670d}\u{52a1}\u{5668}\u{8fd4}\u{56de}\u{4e86}\u{65e0}\u{6548}\u{54cd}\u{5e94}\u{3002}"
    static let errorInvalidPayload = "\u{8fd4}\u{56de}\u{6570}\u{636e}\u{7ed3}\u{6784}\u{4e0e}\u{9884}\u{671f}\u{4e0d}\u{4e00}\u{81f4}\u{3002}"
    static let errorMissingCSRF = "\u{5f53}\u{524d}\u{767b}\u{5f55}\u{6001}\u{7f3a}\u{5c11} bili_jct\u{ff0c}\u{6682}\u{65f6}\u{4e0d}\u{80fd}\u{6267}\u{884c}\u{9700}\u{8981}\u{767b}\u{5f55}\u{9a8c}\u{8bc1}\u{7684}\u{64cd}\u{4f5c}\u{3002}"
    static let trendingLoadFailed = "\u{70ed}\u{641c}\u{52a0}\u{8f7d}\u{5931}\u{8d25}\u{3002}"

    static func uid(_ mid: Int) -> String {
        "UID \(mid)"
    }

    static func watchedPrefix(_ progress: String) -> String {
        "\u{5df2}\u{770b}\u{5230} \(progress)"
    }

    static func videoRemoteResume(_ progress: String) -> String {
        "\u{4e91}\u{7aef}\u{65ad}\u{70b9} \(progress)"
    }

    static func mediaCount(_ count: Int) -> String {
        "\(count) \u{4e2a}\u{5185}\u{5bb9}"
    }

    static func itemCount(_ count: Int) -> String {
        "\(count) \u{9879}"
    }

    static func pageTitle(page: Int, part: String) -> String {
        "P\(page) \(part)"
    }

    static func videoDetailPageCount(_ count: Int) -> String {
        "\(count) \u{4e2a} P"
    }

    static func level(_ level: Int) -> String {
        "Lv\(level)"
    }

    static func coin(_ amount: Double) -> String {
        "\u{786c}\u{5e01} \(String(format: "%.0f", amount))"
    }

    static func requestFailed(code: Int) -> String {
        "\u{8bf7}\u{6c42}\u{5931}\u{8d25}\u{ff08}code \(code)\u{ff09}"
    }

    static func invalidJSON(_ message: String) -> String {
        "\u{8fd4}\u{56de}\u{5185}\u{5bb9}\u{4e0d}\u{662f}\u{5408}\u{6cd5} JSON\u{ff1a}\(message)"
    }

    static func minutesAgo(_ minutes: Int) -> String {
        "\(minutes) \u{5206}\u{949f}\u{524d}"
    }

    static func hoursAgo(_ hours: Int) -> String {
        "\(hours) \u{5c0f}\u{65f6}\u{524d}"
    }

    static func addedToFavorite(_ folderTitle: String) -> String {
        "\u{5df2}\u{52a0}\u{5165}\u{6536}\u{85cf}\u{5939}\u{300c}\(folderTitle)\u{300d}\u{3002}"
    }

    static func removedFromFavorite(_ folderTitle: String) -> String {
        "\u{5df2}\u{4ece}\u{6536}\u{85cf}\u{5939}\u{300c}\(folderTitle)\u{300d}\u{79fb}\u{9664}\u{3002}"
    }

    static func videoCoinedCount(_ count: Int) -> String {
        "\u{5df2}\u{6295} \(count) \u{679a}\u{786c}\u{5e01}\u{3002}"
    }

    static func videoCoinAndLike(_ amount: Int) -> String {
        "\u{6295} \(amount) \u{679a}\u{5e76}\u{540c}\u{65f6}\u{70b9}\u{8d5e}"
    }

    static func qualityLabel(_ label: String) -> String {
        "\(label)"
    }

    static func qualityAudio(_ value: String) -> String {
        "\u{97f3}\u{8f68} \(value)"
    }

    static func danmakuCount(_ count: Int) -> String {
        "\(count) \u{6761}\u{5f39}\u{5e55}"
    }

    static func qualityCount(_ count: Int) -> String {
        "\(count) \(sourceCount)"
    }

    static func resultsSubtitle(_ count: Int) -> String {
        "\(count) \(resultsCount)"
    }

    static func searchContinueWatchingSubtitle(_ count: Int) -> String {
        "\(count) \u{6761}\u{7ed3}\u{679c}\u{53ef}\u{4ee5}\u{76f4}\u{63a5}\u{7eed}\u{64ad}"
    }

    static func searchResultWithResumeSubtitle(total: Int, resumed: Int) -> String {
        "\(total) \u{6761}\u{7ed3}\u{679c}\u{ff0c}\(resumed) \u{6761}\u{53ef}\u{76f4}\u{63a5}\u{7eed}\u{64ad}"
    }

    static func historySubtitle(_ count: Int) -> String {
        "\(count) \(historyCount)"
    }

    static func hotKeywordsSubtitle(_ count: Int) -> String {
        "\(count) \(hotKeywordsCount)"
    }

    static func contentSubtitle(_ count: Int) -> String {
        "\(count) \u{6761}\u{5185}\u{5bb9}"
    }

    static func homeRecommendedSubtitle(_ count: Int) -> String {
        "\(count) \(homeRecommendedSubtitleCount)"
    }

    static func dynamicCountSubtitle(_ count: Int) -> String {
        "\(count) \u{6761}\u{52a8}\u{6001}"
    }

    static func dynamicMediaSubtitle(_ count: Int) -> String {
        "\(count) \u{5f20}\u{56fe}\u{7247}"
    }

    static func dynamicQuotedSubtitle(_ authorName: String) -> String {
        "\u{6765}\u{81ea} \(authorName)"
    }

    static func userRelationEmptyTitle(_ kind: String) -> String {
        "\(kind)\u{5217}\u{8868}\u{6682}\u{65f6}\u{4e3a}\u{7a7a}"
    }

    static func favoriteFoldersSubtitle(_ count: Int) -> String {
        "\(count) \u{4e2a}\u{6536}\u{85cf}\u{5939}"
    }

    static func suggestionSubtitle(_ count: Int) -> String {
        "\(count) \u{6761}\u{8054}\u{60f3}\u{8bcd}"
    }

    static func recommendedKeywordSubtitle(_ count: Int) -> String {
        "\(count) \u{4e2a}\u{63a8}\u{8350}\u{8bcd}"
    }

    static func qrLoginCountdown(_ seconds: Int) -> String {
        "\(qrLoginCountdownPrefix) \(max(0, seconds)) \u{79d2}"
    }

    static func videoCommentsCount(_ count: Int) -> String {
        "\(count) \u{6761}\u{8bc4}\u{8bba}"
    }

    static func videoCommentsPinnedSubtitle(_ count: Int) -> String {
        "\(count) \u{6761}\u{4f18}\u{5148}\u{663e}\u{793a}"
    }

    static func videoCommentsReplyTo(_ name: String) -> String {
        "\u{56de}\u{590d} @\(name)"
    }

    static func playerOverviewPageSubtitle(_ part: String) -> String {
        "\u{5f53}\u{524d}\u{5185}\u{5bb9} · \(part)"
    }

    static func videoCommentsOpenThread(_ count: Int) -> String {
        "\u{67e5}\u{770b}\u{56de}\u{590d}\u{ff08}\(count)\u{6761}\u{ff09}"
    }

    static func videoCommentsReplyComposerTitle(_ name: String) -> String {
        "\u{56de}\u{590d} \(name)"
    }

    static func videoCommentsDraftCount(_ count: Int) -> String {
        "\(count) \u{5b57}"
    }

    static func profileCookieField(_ name: String, isPresent: Bool) -> String {
        "\(name) \(isPresent ? "\u{5df2}\u{5c31}\u{7eea}" : "\u{7f3a}\u{5931}")"
    }

    static func profileCookieFieldCount(_ ready: Int, total: Int) -> String {
        "\(ready)/\(total)"
    }

    static let profileCookieEmptyPreview = "\u{5f53}\u{524d}\u{8fd8}\u{6ca1}\u{6709} Cookie \u{539f}\u{6587}\u{53ef}\u{9884}\u{89c8}"

    static var qrLoginBackgroundCapability: String {
        "\u{5f53} App \u{5207}\u{5230}\u{540e}\u{53f0}\u{65f6}\u{ff0c}\u{767b}\u{5f55}\u{8f6e}\u{8be2}\u{4f1a}\u{5728} iOS \u{5141}\u{8bb8}\u{7684}\u{540e}\u{53f0}\u{65f6}\u{95f4}\u{5185}\u{7ee7}\u{7eed}\u{8fd0}\u{884c}\u{ff1b}\u{5982}\u{679c}\u{7cfb}\u{7edf}\u{63d0}\u{524d}\u{6682}\u{505c}\u{540e}\u{53f0}\u{4efb}\u{52a1}\u{ff0c}\u{56de}\u{5230}\u{524d}\u{53f0}\u{540e}\u{4f1a}\u{81ea}\u{52a8}\u{7eed}\u{8dd1}\u{3002}"
    }
}
