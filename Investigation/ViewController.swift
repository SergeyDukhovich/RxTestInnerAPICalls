//
//  ViewController.swift
//  Investigation
//
//  Created by Sergey Duhovich on 4.10.19.
//  Copyright © 2019 Dukhovich. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

enum ItemError: Error {
    case limitReached
}

class ViewController: UIViewController {

  @IBOutlet private var textField: UITextField!
  private let disposeBag = DisposeBag()
  let api = API()

  override func viewDidLoad() {
    super.viewDidLoad()

    let textQuery = textField.rx
      .text
      .unwrap()
      .filter { $0.count > 3 }
      .debug("user typed")
      .share()

    textQuery.flatMapLatest { [weak self] query -> Observable<[Venue]> in
      guard let self = self else { return Observable<[Venue]>.empty() }
      return self.api.searchVenues(query: query)
    }
    .map { [weak self] venues -> [Observable<[VenueItem]>] in
      guard let self = self else { return [] }
      return venues.map { self.api.itemsByVenue(id: $0.id) }
    }
    .flatMapLatest { itemRequests -> Observable<[VenueItem]> in
      return Observable.concat(itemRequests)
        .scan([], accumulator: { (accumulated, current) -> [VenueItem] in
          let result = accumulated + current
          if result.count <= 10 {
            return result
          } else {
            throw ItemError.limitReached
          }
        })
        .catchErrorJustComplete()
    }
    .debug()
    .subscribe(onNext: { allItems in
      print(allItems)
    })
    .disposed(by: disposeBag)

  }
}

struct Venue: CustomStringConvertible {
  let id: Int
  let name: String

  var description: String {
    return "Venue\(id)"
  }
}

struct VenueItem: CustomStringConvertible {
  let id: Int
  let name: String

  var description: String {
    return "Item\(id)"
  }
}

class API {
  func searchVenues(query: String) -> Observable<[Venue]> {
    return Observable<[Venue]>
      .just(Venue.sampleVenues)
      .delay(RxTimeInterval.seconds(3), scheduler: MainScheduler.instance)
    .debug("simulating API call for query: \(query)")
  }

  func itemsByVenue(id: Int) -> Observable<[VenueItem]> {
    return Observable<[VenueItem]>
      .just(VenueItem.itemsByVenue(id: id))
      .delay(RxTimeInterval.seconds(3), scheduler: MainScheduler.instance)
      .debug("simulating API call for venueId: \(id)")
  }
}


extension Venue {
  static let sampleVenues = [
    Venue(id: 1, name: "venue1"),
    Venue(id: 2, name: "venue2"),
    Venue(id: 3, name: "venue3"),
    Venue(id: 4, name: "venue4"),
    Venue(id: 5, name: "venue5"),
    Venue(id: 6, name: "venue6"),
    Venue(id: 7, name: "venue7"),
    Venue(id: 8, name: "venue8"),
    Venue(id: 8, name: "venue9"),
    Venue(id: 10, name: "venue10"),
    Venue(id: 11, name: "venue11"),
  ]
}

extension VenueItem {
  static func itemsByVenue(id: Int) -> [VenueItem] {
    var result: [VenueItem] = []
    let count = Int.random(in: 1..<6)
    for i in 0..<count {
      let identifier: Int = id * 100 + i
      let item = VenueItem(id: id * 100 + i, name: "item \(identifier)")
      result.append(item)
    }
    return result
  }
}
