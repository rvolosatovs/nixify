fn main() {
    println!(env!("CARGO_CDYLIB_FILE_FOO"));
}

#[test]
fn it_works() {
    assert_eq!(2, 1 + 1);
}
