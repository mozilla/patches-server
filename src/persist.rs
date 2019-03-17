/// Types that implement `Persistent` can have their values persisted to
/// and rebuilt from some external medium.
///
/// Note that this trait is designed with the assumption that only one
/// value of an implementing type will be persisted at a time, as the
/// `rebuild` function provides no means of distinguishing between
/// different values.
pub trait Persistent<Medium> {
  type Error;

  fn persist(&self, &Medium) -> Result<(), Self::Error>;
  fn rebuild(&Medium) -> Result<Self, Self::Error>;
}
