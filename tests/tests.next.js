class ExampleComponent extends BlazeComponent {
  template() {
    // We register the component under a different name.
    return 'ExampleComponent';
  }

  onCreated() {
    this.counter = new ReactiveField(0);
  }

  events() {
    return [{
      'click .increment': this.onClick
    }];
  }

  onClick(event) {
    this.counter(this.counter() + 1);
  }

  customHelper() {
    if (this.counter() > 10) {
      return "Too many times";
    }
    else if (this.counter() === 10) {
      return "Just enough";
    }
    else {
      return "Click more";
    }
  }
}

ExampleComponent.register('ExampleComponentES2015');

var MyComponent = BlazeComponent.getComponent('MyComponent');
class OurComponent extends MyComponent {
  template() {
    // By default it would use "OurComponentES2015" name.
    return 'MyComponent';
  }

  values() {
    return '>>>' + super.values() + '<<<';
  }
}

OurComponent.register('OurComponentES2015');
