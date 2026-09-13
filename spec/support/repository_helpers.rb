# frozen_string_literal: true

module RepositoryHelpers
  def write_repository_cache(path, repositories)
    NyaPr::Repository::CsvStore.
      new(path).
      write(repositories)
  end
end
