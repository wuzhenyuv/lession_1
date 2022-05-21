import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import Logger "mo:ic-logger/Logger";

import ML "MainLogger";

actor {
    type Stats = {
        size: Nat;
        page: Nat;
        count: Nat;
        offset: Nat;
    };

    var size : Nat = 100;
    var page : Nat = 0; 
    var count : Nat = 0; 
    var offset : Nat = 0; 

    var loggers : Buffer.Buffer<L.LenthyLogger> = Buffer.Buffer<L.LenthyLogger>(0);

    func add_logger() : async () {
        if (page == 0 or offset == size) {
            let ml = await ML.LoggerClass();
            loggers.add(ml);
            page := page + 1;
            offset := 0;
        };
    };

    public shared func append(msgs: [Text]) {
        for(msg in msgs.vals()) {
            await add_logger();
            let logger = loggers.get(page - 1);
            logger.append(Array.make(msg));
            count := count + 1;
            offset := offset + 1;
        };
    };

    public shared func view(f: Nat, t: Nat) : async [Text] {
        var result : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

        assert(f >= 0 and f <= t and t + 1 <= count);

        if(count > 0) {
            let from = f / size;
            Debug.print("start from page:" # Nat.toText(from));
            let to = t / size;
            Debug.print("end with page:" # Nat.toText(to));

            for (i in Iter.range(from, to)) {
                Debug.print("process page:" # Nat.toText(i));
                var logger = loggers.get(i);

                let l_from = switch (i == from) {
                    case (true) { f - from * size };
                    case (false) { 0 };
                };

                let l_to = switch (i == to) {
                    case (true) { t - to * size };
                    case (false) { size - 1 };
                };

                var v : Logger.View<Text> = await logger.view(l_from, l_to);

                if(v.messages.size() > 0) {
                    for(j in Iter.range(0, v.messages.size() - 1)) {
                        Debug.print(v.messages[j]);
                        result.add(v.messages[j]);
                    };
                };
            };
        };

        result.toArray()
    };
}
