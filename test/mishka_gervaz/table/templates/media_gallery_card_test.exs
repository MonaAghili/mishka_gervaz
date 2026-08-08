defmodule MishkaGervaz.Table.Templates.MediaGalleryCardTest do
  @moduledoc """
  The media card's layout contract, pinned as markup.

  Rendering the whole template needs a mounted LiveComponent and a loaded page; what these assert is
  narrower and is the part that keeps being got wrong by hand — WHICH CORNER each overlay sits in,
  and whether the actions are something you can see or something you have to find.
  """
  use ExUnit.Case, async: true

  alias MishkaGervaz.Table.Templates.MediaGallery

  @source File.read!("lib/mishka_gervaz/table/templates/media_gallery.ex")

  describe "the card's corners" do
    # A CHECKBOX IS ALWAYS TOP-LEFT and a reader's hand goes there. Anything else in that corner is
    # something they have to move past to select.
    test "selection is top-left" do
      assert @source =~ ~s(class="absolute left-[10px] top-[10px] z-20")
    end

    test "the format badge is top-right" do
      assert @source =~ ~s(class="absolute right-[10px] top-[10px] rounded-md bg-white/85)
    end

    # The star used to share the top-right with nothing; now the badge owns that corner and the star
    # takes the one that is still free.
    test "the featured star is out of the badge's corner" do
      assert @source =~ ~s(class="absolute bottom-2 right-2 z-20 grid size-7)
      refute @source =~ ~s(class="absolute right-2 top-2 z-20 grid size-7)
    end
  end

  describe "the actions" do
    # A HOVER OVERLAY IS NOT AN AFFORDANCE ON A TOUCH SCREEN, and it covers the thumbnail the reader
    # is looking at to decide which file this is.
    test "are a row under the meta, not an overlay over the thumbnail" do
      assert @source =~ ~s(<div :if={@visible_row_actions != []} class="mt-2.5 flex items-center)

      refute @source =~ "group-hover:bg-[#17161a]/25",
             "the hover overlay is gone, so a delete is not one stray cursor away"
    end

    test "they are still Gervaz's own, not hand-drawn buttons" do
      assert @source =~ "<Shared.render_row_actions"
    end
  end

  test "the template still answers for itself" do
    assert MediaGallery.name() == :media_gallery
    assert MediaGallery.label() == "Gallery"
    assert :select in MediaGallery.features()
  end
end
