// Necessary imports for dictionary and nullable types
use core::option::OptionTrait;
use core::dict::Felt252Dict;
use core::dict::Felt252DictTrait;
use core::nullable::{Nullable, NullableTrait};

// Define an enum for FuelType
#[derive(Drop, Copy, PartialEq, Debug, Serde)]
enum CarType {
    Sedan,
    SUV,
    Truck,
    Coupe,
}


// Define a struct for a Car
#[derive(Drop, Copy, PartialEq, Debug, Serde)]
struct Car {
    make: felt252, // Short string (e.g., "Toyota")
    model: felt252, // Short string (e.g., "Camry")
    year: u16,
    car_type: CarType,
    owner: felt252, // Short string for owner name
    color: felt252, // Short string for color (e.g., "Red")
}

// Define the CarRegistry struct, which holds a dictionary of cars
// The key for the dictionary will be a felt252 (e.g., license plate)
// The value will be a Nullable<Car> to allow for dictionary operations
struct CarRegistry {
    cars: Felt252Dict<Nullable<Car>>,
    car_type_count: Felt252Dict<u32>, // Optional: track the number of registered cars
}

// Define a trait for the CarRegistry's functionality
trait CarRegistryTrait {
    fn new() -> CarRegistry;
    fn register_car(ref self: CarRegistry, license_plate: felt252, make: felt252, model: felt252, year: u16, car_type: CarType, owner: felt252, color: felt252);
    fn get_car(ref self: CarRegistry, license_plate: felt252) -> Option<Car>;
    fn get_car_type_count(ref self: CarRegistry, car_type: CarType) -> u32;
    fn update_car(ref self: CarRegistry, license_plate: felt252, make: felt252, model: felt252, year: u16, car_type: CarType, owner: felt252, color: felt252);
    fn reset_registry(ref self: CarRegistry);
}

// Implement the Destruct trait for CarRegistry
// This is necessary because Felt252Dict is a struct member and cannot be dropped directly <a href="https://book.cairo-lang.org/ch12-01-custom-data-structures.html" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">7</a><a href="https://book.cairo-lang.org/ch12-01-custom-data-structures.html" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">10</a>
impl CarRegistryDestruct of Destruct<CarRegistry> {
    fn destruct(self: CarRegistry) nopanic {
        self.cars.squash();
    }
}

// Implement the CarRegistryTrait
impl CarRegistryImpl of CarRegistryTrait {
    // Creates a new, empty CarRegistry
    fn new() -> CarRegistry {
        CarRegistry { cars: Default::default(), car_type_count: Default::default() }
    }

    // Adds a new car to the registry or updates an existing one if the license plate exists
    fn register_car(ref self: CarRegistry, license_plate: felt252, make: felt252, model: felt252, year: u16, car_type: CarType, owner: felt252, color: felt252) {
        // Check if car already exists and adjust old type count
        let old_nullable = self.cars.get(license_plate);
        if !old_nullable.is_null() {
            let old_car = old_nullable.deref();
            let old_type_key = match old_car.car_type {
                CarType::Sedan => 'Sedan',
                CarType::SUV => 'SUV',
                CarType::Truck => 'Truck',
                CarType::Coupe => 'Coupe',
            };
            let old_count = self.car_type_count.get(old_type_key);
            self.car_type_count.insert(old_type_key, old_count - 1);
        }

        // Create and store car
        let car_data = Car { make, model, year, car_type, owner, color };
        self.cars.insert(license_plate, NullableTrait::new(car_data));

        // Update cars_by_type index
        let type_key = match car_type {
            CarType::Sedan => 'Sedan',
            CarType::SUV => 'SUV',
            CarType::Truck => 'Truck',
            CarType::Coupe => 'Coupe',
        };

        let old_car_type_count = self.car_type_count.get(type_key);
        self.car_type_count.insert(type_key, old_car_type_count + 1);
    }

    // Reads a car's data from the registry by its license plate
    fn get_car(ref self: CarRegistry, license_plate: felt252) -> Option<Car> {
        // Dictionaries return the default value if the key is not found.
        // We need to check if the returned Nullable<Car> actually contains a value.
        let nullable_car = self.cars.get(license_plate);
        if nullable_car.is_null() {
            Option::None
        } else {
            Option::Some(nullable_car.deref())
        }
    }

    // Reads a cars count from the registry by its car type
    fn get_car_type_count(ref self: CarRegistry, car_type: CarType) -> u32 {
        // Dictionaries return the default value if the key is not found.
        // We need to check if the returned Nullable<Car> actually contains a value.

        let type_key = match car_type {
            CarType::Sedan => 'Sedan',
            CarType::SUV => 'SUV',
            CarType::Truck => 'Truck',
            CarType::Coupe => 'Coupe',
        };

        let car_number = self.car_type_count.get(type_key);
        car_number
       
    }

    // Updates an existing car's data in the registry
    fn update_car(ref self: CarRegistry, license_plate: felt252, make: felt252, model: felt252, year: u16, car_type: CarType, owner: felt252, color: felt252) {
        // Assert that the car exists before attempting to update
        // In a real scenario, you might want a different error handling or behavior
        let old_nullable = self.cars.get(license_plate);
        assert(!old_nullable.is_null(), 'Car not found for update');

        // Adjust old type count
        let old_car = old_nullable.deref();
        let old_type_key = match old_car.car_type {
            CarType::Sedan => 'Sedan',
            CarType::SUV => 'SUV',
            CarType::Truck => 'Truck',
            CarType::Coupe => 'Coupe',
        };
        let old_count = self.car_type_count.get(old_type_key);
        self.car_type_count.insert(old_type_key, old_count - 1);

        let updated_car_data = Car { make, model, year, car_type, owner, color };
        self.cars.insert(license_plate, NullableTrait::new(updated_car_data));

        // Adjust new type count
        let new_type_key = match car_type {
            CarType::Sedan => 'Sedan',
            CarType::SUV => 'SUV',
            CarType::Truck => 'Truck',
            CarType::Coupe => 'Coupe',
        };
        let new_count = self.car_type_count.get(new_type_key);
        self.car_type_count.insert(new_type_key, new_count + 1);
    }

    // Resets the entire registry by clearing the dictionary and count
    // This effectively creates a new empty dictionary <a href="https://book.cairo-lang.org/ch12-01-custom-data-structures.html" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">10</a>
    fn reset_registry(ref self: CarRegistry) {
        self.cars.squash(); // Clear the dictionary
        self.cars = Default::default(); // Reinitialize with an empty dictionary
        self.car_type_count = Default::default();
    }
}

// Example usage in a main function
#[executable]
fn main() {
    let mut car_registry = CarRegistryTrait::new();

    // Create cars

    car_registry.register_car('PLATE001', 'Mercedes', 'C350', 2025, CarType::Sedan,'John Doe','Black');
    car_registry.register_car('PLATE002',  'BMW', 'X5', 2020, CarType::SUV,'Jane Doe','Pink');
    car_registry.register_car('PLATE003',  'Tesla', 'CyberTruck', 2024, CarType::Truck,'Elon Tunde','Gray');
    car_registry.register_car('PLATE004', 'Mercedes', 'GLK', 2025, CarType::SUV,'OBI Doe','Black');


    // check car count
    let SUV_count = car_registry.get_car_type_count(CarType::SUV);
    let Sedan_count = car_registry.get_car_type_count(CarType::Sedan);

    assert(SUV_count == 2, 'SUV car count wrong');
    assert(Sedan_count == 1, 'Sedan car count wrong');



    // Read a car
    let retrieved_car1 = car_registry.get_car('PLATE001').unwrap();
    assert(retrieved_car1.owner == 'John Doe', 'Car 1 data mismatch');
    assert(retrieved_car1.make == 'Mercedes', 'Make mismatch');

    let non_existent_car = car_registry.get_car('NONEXIST');
    assert!(non_existent_car.is_none(), "Should not find non-existent car");

    // Update a car
    car_registry.update_car('PLATE001', 'Mercedes', 'GLE', 2023, CarType::SUV,'John Doe','Black');
    let check_updated_car1 = car_registry.get_car('PLATE001').unwrap();
    assert(check_updated_car1.model == 'GLE', 'Model not updated');
    assert(check_updated_car1.car_type == CarType::SUV, 'Car type not updated');

    // Reset the registry
    car_registry.reset_registry();
    let after_reset_car = car_registry.get_car('PLATE002');
    assert(after_reset_car.is_none(), 'Registry was not reset');
    
    let SUV_count = car_registry.get_car_type_count(CarType::SUV);
    assert(SUV_count == 0, 'Registered count not reset');
}