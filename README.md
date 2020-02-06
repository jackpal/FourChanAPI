# FourChan

A Swift package for the [4chan.org Read-only HTTP/JSON API](https://github.com/4chan/4chan-API).

# Usage

This package supports both closure and Combine-based networking.

If you load the package in an environment that doesn't support Combine, then the Combine APIs won't be available.

An example of using the API with minimal helper functions:

```
import Foundation
import FourChan

let boards = try? JSONDecoder().decode(Boards.self,
                                       from:Data(contentsOf:FourChanAPIService.Endpoint.boards.url()))

```

An example of closure-based networking is:

```
import FourChan

FourChanAPIService.shared.GET(endpoint:.boards) { (result: Result<Boards, FourChanAPIService.APIError>) in
  print(result)
}
```

An example of Combine-based networking is:

```
import Combine
import FourChan
import SwiftUI

struct FourChanBoardsView : View {
  var loader: FourChanLoader = FourChanLoader()

  var body: some View {
    var categories = loader.fourChan.categories
  
    return List {
      ForEach(0..<categories.count, id:\.self) { i in
        Text(categories[i].title)
      }
    }
  }
}
```

There's currently several layers of Combine-based API. For each endpoint there's both a publisher and a loader.

# Versioning

This module's API is not yet stable, pin to a particular version if you want stability.

# Quality

There are no known bugs. And the library is in use by the "Kleene Star" 4Chan browser app.

Be aware that 4Chan does not provide any guarentees about their API being stable or supported.

