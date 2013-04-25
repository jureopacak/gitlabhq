require 'spec_helper'

describe 'Gitlab::Satellite::MergeAction' do
  before(:each) do
#    TestEnv.init(mailer: false, init_repos: true, repos: true)
    @master = ['master', 'bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a']
    @one_after_stable = ['stable', '6ea87c47f0f8a24ae031c3fff17bc913889ecd00'] #this commit sha is one after stable
    @wiki_branch = ['wiki', '635d3e09b72232b6e92a38de6cc184147e5bcb41'] #this is the commit sha where the wiki branch goes off from master
    @conflicting_metior = ['metior', '313d96e42b313a0af5ab50fa233bf43e27118b3f'] #this branch conflicts with the wiki branch

                                                                               #these commits are quite close together, itended to make string diffs/format patches small
    @close_commit1 = ['2_3_notes_fix', '8470d70da67355c9c009e4401746b1d5410af2e3']
    @close_commit2 = ['scss_refactoring', 'f0f14c8eaba69ebddd766498a9d0b0e79becd633']

  end

  let(:project) { create(:project_with_code) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:merge_request_fork) { create(:merge_request) }
  describe '#commits_between' do
    context 'on fork' do
      it 'should get proper commits between' do
        merge_request_fork.target_branch = @one_after_stable[0]
        merge_request_fork.source_branch = @master[0]
        commits = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).commits_between
        commits.first.id.should == @one_after_stable[1]
        commits.last.id.should == @master[1]

        merge_request_fork.target_branch = @wiki_branch[0]
        merge_request_fork.source_branch = @master[0]
        commits = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).commits_between
        commits.first.id.should == @wiki_branch[1]
        commits.last.id.should == @master[1]
      end
    end

    context 'between branches' do
      it 'should get proper commits between' do
        merge_request.target_branch = @one_after_stable[0]
        merge_request.source_branch = @master[0]
        commits = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).commits_between
        commits.first.id.should == @one_after_stable[1]
        commits.last.id.should == @master[1]

        merge_request.target_branch = @wiki_branch[0]
        merge_request.source_branch = @master[0]
        commits = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).commits_between
        commits.first.id.should == @wiki_branch[1]
        commits.last.id.should == @master[1]
      end
    end
  end


  describe '#format_patch' do
    context 'on fork' do
      it 'should build a format patch' do
        merge_request_fork.target_branch = @close_commit1[0]
        merge_request_fork.source_branch = @close_commit2[0]
        patch = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).format_patch
        (patch.include? "From #{@close_commit2[1]}").should be_true
        (patch.include? "From #{@close_commit1[1]}").should be_true
      end
    end

    context 'between branches' do
      it 'should build a format patch' do
        merge_request.target_branch = @close_commit1[0]
        merge_request.source_branch = @close_commit2[0]
        patch = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).format_patch
        (patch.include? "From #{@close_commit2[1]}").should be_true
        (patch.include? "From #{@close_commit1[1]}").should be_true
      end
    end
  end


  describe '#diffs_between_satellite tested against diff_in_satellite' do
    context 'on fork' do
      it 'should get proper diffs' do
        merge_request_fork.target_branch = @close_commit1[0]
        merge_request_fork.source_branch = @master[0]
        diffs = Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).diffs_between_satellite

        merge_request_fork.target_branch = @close_commit1[0]
        merge_request_fork.source_branch = @master[0]
        diff = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request_fork).diffs_between_satellite

        diffs.each {|a_diff| (diff.include? a_diff.diff).should be_true}
      end
    end

    context 'between branches' do
      it 'should get proper diffs' do
        merge_request.target_branch = @close_commit1[0]
        merge_request.source_branch = @wiki_branch[0]
        diffs = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).diffs_between_satellite


        merge_request.target_branch = @close_commit1[0]
        merge_request.source_branch = @master[0]
        diff = Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).diffs_between_satellite

        diffs.each {|a_diff| (diff.include? a_diff.diff).should be_true}
      end
    end
  end


  describe '#can_be_merged?' do
    context 'on fork' do
      it 'return true or false depending on if something is mergable' do
        merge_request_fork.target_branch = @one_after_stable[0]
        merge_request_fork.source_branch = @master[0]
        Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).can_be_merged?.should be_true

        merge_request_fork.target_branch = @conflicting_metior[0]
        merge_request_fork.source_branch = @wiki_branch[0]
        Gitlab::Satellite::MergeAction.new(merge_request_fork.author, merge_request_fork).can_be_merged?.should be_false
      end
    end

    context 'between branches' do
      it 'return true or false depending on if something is mergable' do
        merge_request.target_branch = @one_after_stable[0]
        merge_request.source_branch = @master[0]
        Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).can_be_merged?.should be_true

        merge_request.target_branch = @conflicting_metior[0]
        merge_request.source_branch = @wiki_branch[0]
        Gitlab::Satellite::MergeAction.new(merge_request.author, merge_request).can_be_merged?.should be_false
      end
    end
  end

end