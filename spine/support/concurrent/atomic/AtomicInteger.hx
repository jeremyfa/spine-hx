package spine.support.concurrent.atomic;

abstract AtomicInteger(Int) {

    inline public function new() {
        this = 0;
    }

    inline public function getAndIncrement() {
        return this++;
    }

}
