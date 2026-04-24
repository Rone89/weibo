import Foundation

enum BiliBaseURL {
    static let api = "https://api.bilibili.com"
    static let app = "https://app.bilibili.com"
    static let web = "https://www.bilibili.com"
    static let search = "https://s.search.bilibili.com"
    static let account = "https://account.bilibili.com"
    static let passport = "https://passport.bilibili.com"
    static let live = "https://api.live.bilibili.com"
}

enum BiliEndpoint {
    static let nav = "/x/web-interface/nav"
    static let recommendFeed = "/x/web-interface/wbi/index/top/feed/rcmd"
    static let hotVideos = "/x/web-interface/popular"
    static let liveFeedIndex = "/xlive/app-interface/v2/index/feed"
    static let pgcRank = "/pgc/web/rank/list"

    static let searchDefault = "/x/web-interface/wbi/search/default"
    static let searchByType = "/x/web-interface/wbi/search/type"
    static let searchSuggest = "/main/suggest"
    static let searchTrending = "/main/hotword"
    static let searchRecommend = "/x/v2/search/recommend"

    static let dynamicFeed = "/x/polymer/web-dynamic/v1/feed/all"
    static let dynamicDetail = "/x/polymer/web-dynamic/v1/detail"

    static let qrCodeAuthCode = "/x/passport-tv-login/qrcode/auth_code"
    static let qrCodePoll = "/x/passport-tv-login/qrcode/poll"

    static let memberCardInfo = "/x/web-interface/card"
    static let userRelationStat = "/x/relation/stat"
    static let userRelation = "/x/relation"
    static let userRelationModify = "/x/relation/modify"
    static let userFollowings = "/x/relation/followings"
    static let userFans = "/x/relation/fans"
    static let userArchiveSearch = "/x/space/wbi/arc/search"

    static let userFavoriteFolders = "/x/v3/fav/folder/created/list"
    static let userFavoriteFoldersAll = "/x/v3/fav/folder/created/list-all"
    static let favoriteFolderDetail = "/x/v3/fav/resource/list"
    static let favoriteVideoBatchDeal = "/x/v3/fav/resource/batch-deal"
    static let favoriteFolderSubscribe = "/x/v3/fav/folder/fav"
    static let favoriteFolderUnsubscribe = "/x/v3/fav/folder/unfav"

    static let historyList = "/x/web-interface/history/cursor"
    static let historyDelete = "/x/v2/history/delete"
    static let historyClear = "/x/v2/history/clear"
    static let watchLaterList = "/x/v2/history/toview/web"
    static let watchLaterAdd = "/x/v2/history/toview/add"
    static let watchLaterDelete = "/x/v2/history/toview/v2/dels"
    static let watchLaterClear = "/x/v2/history/toview/clear"

    static let videoDetail = "/x/web-interface/view"
    static let videoRelation = "/x/web-interface/archive/relation"
    static let likeVideo = "/x/web-interface/archive/like"
    static let coinVideo = "/x/web-interface/coin/add"
    static let relatedVideos = "/x/web-interface/archive/related"
    static let replyMain = "/x/v2/reply/main"
    static let replyList = "/x/v2/reply"
    static let replyLike = "/x/v2/reply/action"
    static let replyReplyList = "/x/v2/reply/reply"
    static let replyAdd = "/x/v2/reply/add"
    static let historyReport = "/x/v2/history/report"
    static let heartbeat = "/x/click-interface/web/heartbeat"
    static let videoPlayURL = "/x/player/wbi/playurl"
    static let playInfo = "/x/player/wbi/v2"
    static let favoriteVideoUnfavAll = "/x/v3/fav/resource/unfav-all"

    static let getCoin = "/site/getCoin"
}
