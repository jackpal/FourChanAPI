# FourChan

A Swift package for the [4chan.org Read-only HTTP/JSON API](https://github.com/4chan/4chan-API).

# Features

- Typesafe URLs for
  - the 4chan API (FourChanAPIEndpoint)
  - the experimental 4chan mobile search API (FourChanAPIEndpoint.search)
  - the 4chan web site. (FourChanWebEndpoint)
- Codable structs for all the 4chan API result types (e.g. Post).
  - the structs implement Identifiable where possible.
- Helpers for making network requests in a variety of styles:
  - using callbacks.
  - using Combine publishers.
  - using Combine/SwiftUI ObsevableObjects.


# Usage

This package supports both callback and Combine-based networking.

If you load the package in an environment (like Linux) that doesn't support Combine, then the Combine APIs won't be available.

An example of using the API with minimal helper functions:

```
import Foundation
import FourChan

let boards = try? JSONDecoder().decode(Boards.self,
                                       from:Data(contentsOf:FourChanAPIEndpoint.boards.url()))

```

An example of callback-based networking is:

```
import FourChan

FourChanAPIService.shared.GET(endpoint:.boards) { (result: Result<Boards, FourChanAPIService.APIError>) in
  print(result)
}
```

An example of Combine-based networking:

```
import Combine

FourChanService.shared.posts(board:"w")
  .tryMap{ postInContext in
    postInContext.imageURL
  }
  .sink(
    receiveCompletion: { completion in
    if case .failure(_) = completion {
        print(".sink() failed ", String(describing: completion))
      }
    },
    receiveValue: { imageURL in
      print(imageURL)
    }
  )
```

A SwiftUI example:

```
import FourChan
import SwiftUI

struct FourChanBoardsView : View {
  var loader: FourChanLoader = FourChanLoader()

  var body: some View {
    var categories = loader.data?.categories ?? []
  
    return List {
      ForEach(0..<categories.count, id:\.self) { i in
        Text(categories[i].title)
      }
    }
  }
}
```

# Versioning

This module's API is not yet stable, pin to a particular version if you want stability.

# Quality

There are no known bugs. And the library is in use by the "Kleene Star" 4Chan browser app.

Be aware that 4Chan does not provide any guarentees about their API being stable or supported.
