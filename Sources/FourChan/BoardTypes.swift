import Foundation

// Ideally this information could be downloaded from the 4chan API.

let boardTypes: [String: [String]] = [
  "Japanese Culture":
    ["a", "c", "w", "m", "cgl", "cm", "f", "n",
    "jp", "vp"],
  "Video Games":
    ["v", "vg", "vp", "vr"],
 "Interests" :
    ["co", "g", "tv", "k", "o", "an",
     "tg", "sp", "asp", "sci", "his", "int", "out",
     "toy"],
 "Creative" :
    ["i", "po", "p", "ck", "ic", "wg", "lit", "mu", "fa",
    "3", "gd", "diy", "wsg", "qst"],
 "Other":
    ["biz", "trv", "fit", "x", "adv", "lgbt", "mlp", "news", "wsr", "vip"],
 "Adult":
    ["s", "hc", "hm", "h", "e", "u", "d", "y", "t",
    "hr", "gif", "aco", "r"],
 "Misc":
    ["b", "bant", "r9k", "pol", "soc", "s4s"]
]

let uncategorized = "Uncategorized"

let boardCategories: [String] = [
  "Japanese Culture",
  "Video Games",
  "Interests",
  "Creative",
  "Adult",
  "Other",
  "Misc",
  uncategorized
]

let nsfwBoardCategories = Set(["Adult", "Misc", uncategorized])

let lowImageBoards = Set(["f"])

class CategoryDB {
  let boardNameCategory: [String: String]
  
  init() {
    var map: [String: String] = [:]
    for (category, boardTitles) in boardTypes {
      for boardTitle in boardTitles {
        map[boardTitle] = category
      }
    }
    boardNameCategory = map
  }
  
  func category(title: String) -> String? {
    boardNameCategory[title]
  }
}

let staticCategoryDB = CategoryDB()

public struct FourChan {
  public let categories: [Category]
  // Maps boardName to category.
  public let boardMap: [String: Category]
  
  init(categories: [Category] = [], boardMap: [String: Category] = [:]) {
    self.categories = categories
    self.boardMap = boardMap
  }
}

public struct Category {
  public let title: String
  public let boards: Boards
  public let nsfw: Bool
}

func categorize(boards: Boards) -> FourChan {
  var dict = [String: [Board]]()
  boards.boards.forEach { board in
    let title = board.board
    if lowImageBoards.contains(title) {
      return
    }
    let category =
      staticCategoryDB.category(title:title) ?? uncategorized
    dict.merge([category: [board]]) {
      $0 + $1
    }
  }
  var categories: [Category] = []
  var boardMap: [BoardName:Category] = [:]
  for categoryName in boardCategories {
    if let boards = dict[categoryName] {
      let category = Category(
        title:categoryName,
        boards:Boards(boards:boards),
        nsfw:nsfwBoardCategories.contains(categoryName)
      )
      categories.append(category)
      for board in boards {
        boardMap[board.board] = category
      }
    }
  }
  return FourChan(categories:categories, boardMap:boardMap)
}
